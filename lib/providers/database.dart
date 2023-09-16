import 'package:crs_manager/models/asset.dart';
import 'package:crs_manager/models/inward_challan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';

import '../models/buyer.dart';
import '../models/challan.dart';
import '../models/condition.dart';
import '../models/template.dart';
import '../utils/exceptions.dart';

class DatabaseModel extends ChangeNotifier {
  List<Buyer> buyers = [];
  List<Challan> challans = [];
  Map<String, Map<String, dynamic>> secrets = {};
  List<Template> templates = [];
  // UUID -> Asset
  Map<String, Asset> assets = {};
  List<AssetHistory> assetHistory = [];
  List<InwardChallan> inwardChallans = [];

  late SupabaseClient _client;
  bool connected = false;
  bool loadingData = false;

  Future<void> connect(String host, String key) async {
    try {
      // Try to connect
      await Supabase.initialize(
        url: host,
        anonKey: key,
      );

      // Check if the connection is valid by fetching a single row from the challans table

      await Supabase.instance.client.from("challans").select().limit(1);
    } catch (err) {
      Supabase.instance.dispose();
      throw DatabaseConnectionError();
    }

    _client = Supabase.instance.client;
    connected = true;
  }

  Future<void> loadCache() async {
    loadingData = true;

    const buyerPageCount = 10;
    const challanPageCount = 25;
    const assetPageCount = 25;
    const assetHistoryPageCount = 25;

    templates =
        (await _client.from("templates").select<List<Map<String, dynamic>>>())
            .map(
              (e) => Template.fromMap(e),
            )
            .toList();

    // Load initial assets
    assets = {
      for (var element in (await _client
              .from("assets")
              .select<List<Map<String, dynamic>>>()
              .order("created_at")
              .limit(assetPageCount))
          .map((assetMap) {
        var template = templates
            .firstWhere((template) => assetMap["template"] == template.id);
        assetMap["template"] = template.toMap();
        return Asset.fromMap(assetMap);
      }))
        element.uuid: element
    };

    // Load rest of the assets instantly
    // This is needed for challan products later
    await loadAssets(assetPageCount);

    // Load initial buyers
    buyers = (await _client
            .from("buyers")
            .select<List<Map<String, dynamic>>>()
            .order("name", ascending: true)
            .limit(buyerPageCount))
        .map((e) => Buyer.fromMap(e))
        .toList();

    // Load rest of the buyers in background
    loadBuyers(buyerPageCount);

    // Load initial challans
    challans = (await _client
            .from("challans")
            .select<List<Map<String, dynamic>>>()
            .order("created_at")
            .limit(challanPageCount))
        .map((e) {
      for (var i = 0; i < (e["products"] as List).length; i++) {
        var rawProduct = e["products"][i];
        if (rawProduct["assets"] != null) {
          // That means it contains asset ids, replace them with actual assets
          rawProduct["assets"] =
              rawProduct["assets"].map((assetId) => assets[assetId]).toList();
        }
      }
      return Challan.fromMap(e);
    }).toList();

    // Load rest of the challans in background
    loadChallans(challanPageCount);

    // Load initial inward challans
    inwardChallans = (await _client
            .from("inward_challans")
            .select<List<Map<String, dynamic>>>()
            .order("created_at")
            .limit(challanPageCount))
        .map((e) {
      for (var i = 0; i < (e["products"] as List).length; i++) {
        var rawProduct = e["products"][i];
        if (rawProduct["assets"] != null) {
          // That means it contains asset ids, replace them with actual assets
          rawProduct["assets"] =
              rawProduct["assets"].map((assetId) => assets[assetId]).toList();
        }
      }
      return InwardChallan.fromMap(e);
    }).toList();

    // Load rest of the inward challans in background
    loadInwardChallans(challanPageCount);

    secrets =
        (await _client.from("secrets").select<List<Map<String, dynamic>>>())
            .asMap()
            .map((index, row) => MapEntry(row["name"], row["value"]));

    // Load initial assetHistory
    assetHistory = (await _client
            .from("assets_history")
            .select<List<Map<String, dynamic>>>()
            .order("when")
            .limit(assetHistoryPageCount))
        .map((e) => AssetHistory.fromMap(e))
        .toList();

    // Load rest of the assetHistory in background
    loadAssetHistory(assetHistoryPageCount);

    notifyListeners();
  }

  Future<void> loadBuyers(int buyerPageCount) async {
    Future<int> fetchMoreBuyers(int offset, int limit) async {
      final from = offset * limit;
      final to = from + limit - 1;
      var newBuyers = (await _client
              .from("buyers")
              .select<List<Map<String, dynamic>>>()
              .order("name", ascending: true)
              .range(from, to))
          .map((e) => Buyer.fromMap(e))
          .toList();
      buyers.addAll(newBuyers);
      return newBuyers.length;
    }

    int buyerOffset = 1;
    while (true) {
      var newBuyersLength = await fetchMoreBuyers(buyerOffset, buyerPageCount);
      buyerOffset += 1;
      notifyListeners();
      if (newBuyersLength < buyerPageCount) {
        break;
      }
    }
  }

  Future<void> loadChallans(int challanPageCount) async {
    Future<int> fetchMoreChallans(int offset, int limit) async {
      final from = offset * limit;
      final to = from + limit - 1;
      var newChallans = (await _client
              .from("challans")
              .select<List<Map<String, dynamic>>>()
              .order("created_at")
              .range(from, to))
          .map((e) {
        for (var i = 0; i < (e["products"] as List).length; i++) {
          var rawProduct = e["products"][i];
          if (rawProduct["assets"] != null) {
            // That means it contains asset ids, replace them with actual assets
            rawProduct["assets"] =
                rawProduct["assets"].map((assetId) => assets[assetId]).toList();
          }
        }
        return Challan.fromMap(e);
      }).toList();
      challans.addAll(newChallans);
      return newChallans.length;
    }

    int challanOffset = 1;
    while (true) {
      var newChallansLength =
          await fetchMoreChallans(challanOffset, challanPageCount);
      challanOffset += 1;
      notifyListeners();
      if (newChallansLength < challanPageCount) {
        break;
      }
    }
    loadingData = true;
    notifyListeners();
  }

  Future<void> loadAssets(int assetPageCount) async {
    Future<int> fetchMoreAssets(int offset, int limit) async {
      final from = offset * limit;
      final to = from + limit - 1;
      var newAssets = (await _client
              .from("assets")
              .select<List<Map<String, dynamic>>>()
              .order("created_at")
              .range(from, to))
          .map((assetMap) {
        var template = templates
            .firstWhere((template) => assetMap["template"] == template.id);
        assetMap["template"] = template.toMap();
        return Asset.fromMap(assetMap);
      }).toList();
      assets.addAll({for (var element in newAssets) element.uuid: element});
      return newAssets.length;
    }

    int assetOffset = 1;
    while (true) {
      var newAssetsLength = await fetchMoreAssets(assetOffset, assetPageCount);
      assetOffset += 1;
      notifyListeners();
      if (newAssetsLength < assetPageCount) {
        break;
      }
    }
    loadingData = true;
    notifyListeners();
  }

  Future<void> loadAssetHistory(int assetHistoryPageCount) async {
    Future<int> fetchMoreAssetHistory(int offset, int limit) async {
      final from = offset * limit;
      final to = from + limit - 1;
      var newAssetHistory = (await _client
              .from("assets_history")
              .select<List<Map<String, dynamic>>>()
              .order("when")
              .range(from, to))
          .map((e) => AssetHistory.fromMap(e))
          .toList();
      assetHistory.addAll(newAssetHistory);
      return newAssetHistory.length;
    }

    int assetHistoryOffset = 1;
    while (true) {
      var newAssetHistoryLength = await fetchMoreAssetHistory(
          assetHistoryOffset, assetHistoryPageCount);
      assetHistoryOffset += 1;
      notifyListeners();
      if (newAssetHistoryLength < assetHistoryPageCount) {
        break;
      }
    }
    loadingData = true;
    notifyListeners();
  }

  Future<void> loadInwardChallans(int challanPageCount) async {
    Future<int> fetchMoreInwardChallans(int offset, int limit) async {
      final from = offset * limit;
      final to = from + limit - 1;
      var newInwardChallans = (await _client
              .from("inward_challans")
              .select<List<Map<String, dynamic>>>()
              .order("created_at")
              .range(from, to))
          .map((e) {
        for (var i = 0; i < (e["products"] as List).length; i++) {
          var rawProduct = e["products"][i];
          if (rawProduct["assets"] != null) {
            // That means it contains asset ids, replace them with actual assets
            rawProduct["assets"] =
                rawProduct["assets"].map((assetId) => assets[assetId]).toList();
          }
        }
        return InwardChallan.fromMap(e);
      }).toList();
      inwardChallans.addAll(newInwardChallans);
      return newInwardChallans.length;
    }

    int challanOffset = 1;
    while (true) {
      var newInwardChallansLength =
          await fetchMoreInwardChallans(challanOffset, challanPageCount);
      challanOffset += 1;
      notifyListeners();
      if (newInwardChallansLength < challanPageCount) {
        break;
      }
    }
    loadingData = true;
    notifyListeners();
  }

  Future<List<Buyer>> getBuyers() async {
    return buyers;
  }

  Future<Buyer> createBuyer(
      {required String name,
      required String address,
      required String gst,
      required String state,
      required String alias}) async {
    final response = await _client.from("buyers").insert({
      "name": name.toUpperCase(),
      "address": address.toUpperCase(),
      "gst": gst.toUpperCase(),
      "state": state.toUpperCase(),
      "alias": alias.toUpperCase(),
    }).select();
    if (response == null) {
      throw DatabaseError();
    }
    final buyer = Buyer.fromMap(response[0]);
    buyers.add(buyer);
    notifyListeners();
    return buyer;
  }

  Future<void> updateBuyer({
    required Buyer buyer,
    String? name,
    String? address,
    String? gst,
    String? state,
    String? alias,
  }) async {
    if (name == null &&
        address == null &&
        gst == null &&
        state == null &&
        alias == null) {
      return;
    }

    await _client.from("buyers").update({
      "name": name?.toUpperCase() ?? buyer.name,
      "address": address?.toUpperCase() ?? buyer.address,
      "gst": gst?.toUpperCase() ?? buyer.gst,
      "state": state?.toUpperCase() ?? buyer.state,
      "alias": alias?.toUpperCase() ?? buyer.alias,
    }).eq("id", buyer.id);

    buyers = buyers.map((e) {
      if (e.id == buyer.id) {
        return Buyer(
          id: e.id,
          name: name?.toUpperCase() ?? e.name,
          address: address?.toUpperCase() ?? e.address,
          gst: gst?.toUpperCase() ?? e.gst,
          state: state?.toUpperCase() ?? e.state,
          alias: alias?.toUpperCase() ?? e.alias,
        );
      }
      return e;
    }).toList();

    notifyListeners();
  }

  Future<void> deleteBuyer(Buyer buyer) async {
    // Check if the buyer is used in any challan
    final challans = this
        .challans
        .where((challan) => challan.buyer.name == buyer.name)
        .toList();
    if (challans.isNotEmpty) {
      throw BuyerInUseError();
    }

    await _client.from("buyers").delete().eq("id", buyer.id);
    buyers.remove(buyer);
    notifyListeners();
  }

  Future<Map<String, dynamic>> getNextChallanInfo() async {
    var now = DateTime.now();
    var endOfFiscalYear = DateTime(now.year, 3, 31, 23, 59, 59);
    var session = now.isAfter(endOfFiscalYear)
        ? "${now.year}-${now.year + 1}"
        : "${now.year - 1}-${now.year}";
    var number = (await _client
                .from("challans")
                .select("number")
                .eq("session", session)
                .order("number", ascending: false)
                .limit(1) as List)
            .firstOrNull?["number"] ??
        0;
    number += 1;

    return {"number": number, "session": session};
  }

  Future<Map<String, dynamic>> getNextInwardChallanInfo() async {
    var now = DateTime.now();
    var endOfFiscalYear = DateTime(now.year, 3, 31, 23, 59, 59);
    var session = now.isAfter(endOfFiscalYear)
        ? "${now.year}-${now.year + 1}"
        : "${now.year - 1}-${now.year}";

    var sessionInwardChallans = inwardChallans
        .where((element) => element.session == session)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    if (sessionInwardChallans.isEmpty) {
      return {"number": 1, "session": session};
    }

    int number = 0;
    for (var inwardChallan in sessionInwardChallans) {
      if (inwardChallan.number - number == 1) {
        number += 1;
      }
    }

    if (number == 0) {
      return {"number": 1, "session": session};
    }

    return {"number": number + 1, "session": session};
  }

  Future<List<Challan>> getChallans() async {
    return challans;
  }

  Future<Challan> createChallan(
      {required int number,
      required String session,
      required Buyer buyer,
      required List<Product> products,
      required int productsValue,
      required String deliveredBy,
      required String vehicleNumber,
      required String notes,
      required bool received,
      required bool digitallySigned}) async {
    final response = await _client.from("challans").insert({
      "session": session,
      "number": number,
      "buyer": buyer.toMap(),
      "products": products.map((e) => e.toMap()).toList(),
      "products_value": productsValue,
      "delivered_by": deliveredBy.toUpperCase(),
      "vehicle_number": vehicleNumber.toUpperCase(),
      "notes": notes,
      "received": received,
      "digitally_signed": digitallySigned
    }).select();

    if (response == null) {
      throw DatabaseError();
    }

    var rawChallan = response[0];
    for (var i = 0; i < (rawChallan["products"] as List).length; i++) {
      var rawProduct = rawChallan["products"][i];
      if (rawProduct["assets"] != null) {
        // That means it contains asset ids, replace them with actual assets
        rawProduct["assets"] =
            rawProduct["assets"].map((assetId) => assets[assetId]).toList();
      }
    }

    final challan = Challan.fromMap(rawChallan);
    challans.insert(0, challan);
    notifyListeners();
    return challan;
  }

  Future<void> updateChallan({
    required Challan challan,
    Buyer? buyer,
    List<Product>? products,
    int? productsValue,
    int? billNumber,
    String? deliveredBy,
    String? vehicleNumber,
    String? notes,
    bool? received,
    bool? digitallySigned,
    bool? cancelled,
    String? photoId,
  }) async {
    if (buyer == null &&
        products == null &&
        productsValue == null &&
        deliveredBy == null &&
        vehicleNumber == null &&
        notes == null &&
        received == null &&
        digitallySigned == null &&
        cancelled == null &&
        billNumber == null &&
        photoId == null) {
      return;
    }

    await _client
        .from("challans")
        .update({
          "buyer": (buyer ?? challan.buyer).toMap(),
          "products": (products ?? challan.products)
              .map(
                (e) => e.toMap(),
              )
              .toList(),
          "products_value": productsValue ?? challan.productsValue,
          "bill_number": billNumber,
          "delivered_by": deliveredBy?.toUpperCase() ?? challan.deliveredBy,
          "vehicle_number":
              vehicleNumber?.toUpperCase() ?? challan.vehicleNumber,
          "notes": notes ?? challan.notes,
          "received": received ?? challan.received,
          "digitally_signed": digitallySigned ?? challan.digitallySigned,
          "cancelled": cancelled ?? challan.cancelled,
          "photo_id": photoId ?? challan.photoId,
        })
        .eq("session", challan.session)
        .eq("number", challan.number)
        .eq("id", challan.id);

    challans = challans.map((e) {
      if (e.id == challan.id) {
        return Challan(
          id: e.id,
          session: e.session,
          number: e.number,
          createdAt: e.createdAt,
          buyer: buyer ?? e.buyer,
          products: products ?? e.products,
          productsValue: productsValue ?? e.productsValue,
          billNumber: billNumber,
          deliveredBy: deliveredBy?.toUpperCase() ?? e.deliveredBy,
          vehicleNumber: vehicleNumber?.toUpperCase() ?? e.vehicleNumber,
          notes: notes ?? e.notes,
          received: received ?? e.received,
          digitallySigned: digitallySigned ?? e.digitallySigned,
          cancelled: cancelled ?? e.cancelled,
          photoId: photoId ?? e.photoId,
        );
      }
      return e;
    }).toList();
    notifyListeners();
  }

  List<Challan> filterChallan({required List<Condition> conditions}) {
    var filteredChallans = List<Challan>.from(challans);

    for (var condition in conditions) {
      switch (condition.type) {
        case ConditionType.buyers:
          // Condition value will be list of buyer
          filteredChallans = filteredChallans.where((challan) {
            for (Buyer b in condition.value) {
              if (challan.buyer.name.toLowerCase() == b.name.toLowerCase()) {
                return true;
              }
            }
            return false;
          }).toList();
          break;
        case ConditionType.date:
          // Condition value will be DateTimeRange
          var val = DateTimeRange(
              start: condition.value.start,
              end: (condition.value.end as DateTime)
                  .copyWith(hour: 23, minute: 59, second: 59));

          filteredChallans = filteredChallans.where((challan) {
            return val.start.isBefore(challan.createdAt) &&
                val.end.isAfter(challan.createdAt);
          }).toList();
          break;
        case ConditionType.product:
          // Condition value will be string
          // If string is in any product's description, serial, or additional description
          // then challan will be included

          filteredChallans = filteredChallans.where((challan) {
            for (Product p in challan.products) {
              if (p.description
                      .toLowerCase()
                      .contains(condition.value.toLowerCase()) ||
                  p.serial
                      .toLowerCase()
                      .contains(condition.value.toLowerCase()) ||
                  p.additionalDescription
                      .toLowerCase()
                      .contains(condition.value.toLowerCase())) {
                return true;
              }
            }
            return false;
          }).toList();
          break;
        default:
          break;
      }
    }

    return filteredChallans;
  }

  Future<Template> createTemplate({
    required String name,
    required List<Field> fields,
    required Map<String, String> productLink,
    required String metadata,
  }) async {
    final response = await _client.from("templates").insert({
      "name": name,
      "fields": fields.map((e) => e.toMap()).toList(),
      "product_link": productLink,
      "metadata": metadata,
    }).select();

    if (response == null) {
      throw DatabaseError();
    }

    final template = Template.fromMap(response[0]);
    templates.add(template);
    notifyListeners();
    return template;
  }

  Future<Template> updateTemplate({
    required Template template,
    String? name,
    List<Field>? fields,
    Map<String, String>? productlink,
    String? metadata,
  }) async {
    if (name == null && fields == null) {
      return template;
    }

    await _client.from("templates").update({
      "name": name ?? template.name,
      "fields": fields?.map((e) => e.toMap()).toList() ?? template.fields,
      "product_link": productlink ?? template.productLink,
      "metadata": metadata ?? template.metadata,
    }).eq("id", template.id);

    templates = templates.map((e) {
      if (e.id == template.id) {
        return Template(
            id: e.id,
            name: name ?? e.name,
            fields: fields ?? e.fields,
            productLink: productlink ?? e.productLink,
            metadata: metadata ?? e.metadata);
      }
      return e;
    }).toList();

    // Change template of all assets using this template
    assets = assets.map((key, value) {
      if (value.template.id == template.id) {
        return MapEntry(
            key,
            Asset(
              id: value.id,
              uuid: value.uuid,
              createdAt: value.createdAt,
              location: value.location,
              purchaseCost: value.purchaseCost,
              purchaseDate: value.purchaseDate,
              additionalCost: value.additionalCost,
              purchasedFrom: value.purchasedFrom,
              template: Template(
                  id: template.id,
                  name: name ?? template.name,
                  fields: fields ?? template.fields,
                  productLink: productlink ?? template.productLink,
                  metadata: metadata ?? template.metadata),
              customFields: value.customFields,
              notes: value.notes,
              recoveredCost: value.recoveredCost,
            ));
      }
      return MapEntry(key, value);
    });

    notifyListeners();
    return Template(
        id: template.id,
        name: name ?? template.name,
        fields: fields ?? template.fields,
        productLink: productlink ?? template.productLink,
        metadata: metadata ?? template.metadata);
  }

  Future<void> deleteTemplate(Template template) async {
    // Check if the template is used in any asset
    final assets = this
        .assets
        .values
        .where((asset) => asset.template.id == template.id)
        .toList();
    if (assets.isNotEmpty) {
      throw TemplateInUseError();
    }

    await _client.from("templates").delete().eq("id", template.id);
    templates.remove(template);
    notifyListeners();
  }

  Future<List<Asset>> createAsset({
    required String location,
    required int purchaseCost,
    required DateTime purchaseDate,
    required List<AdditionalCost> additionalCost,
    required String purchasedFrom,
    required Template template,
    required Map<String, FieldValue> customFields,
    required String notes,
    required int recoveredCost,
    int count = 1,
  }) async {
    final response = (await _client
        .from("assets")
        .insert(List.filled(count, {
          "location": location,
          "purchase_cost": purchaseCost,
          "purchase_date": purchaseDate.toUtc().toIso8601String(),
          "additional_cost": additionalCost.map((e) => e.toMap()).toList(),
          "purchased_from": purchasedFrom,
          "template": template.id,
          "custom_fields":
              customFields.map((key, value) => MapEntry(key, value.getValue())),
          "notes": notes,
          "recovered_cost": recoveredCost,
        }))
        .select());

    if (response == null) {
      throw DatabaseError();
    }
    for (var element in response) {
      element["template"] = template.toMap();
    }

    var assets =
        List<Asset>.from(response.map((e) => Asset.fromMap(e)).toList());
    await _insertHistory(assets: assets, created: true);

    for (var asset in assets) {
      this.assets[asset.uuid] = asset;
    }

    notifyListeners();
    return assets;
  }

  /// All the assets will be updated with the same values
  /// So all the assets must have same values (basically an asset group)
  Future<List<Asset>> updateAsset({
    required List<Asset> assets,
    String? location,
    int? purchaseCost,
    DateTime? purchaseDate,
    List<AdditionalCost>? additionalCost,
    String? purchasedFrom,
    Map<String, FieldValue>? customFields,
    String? notes,
    int? recoveredCost,
    int? challanId,
    int? challanType,
  }) async {
    if (location == null &&
        purchaseCost == null &&
        purchaseDate == null &&
        additionalCost == null &&
        purchasedFrom == null &&
        customFields == null &&
        notes == null &&
        recoveredCost == null) {
      return assets;
    }

    final response = (await _client
        .from("assets")
        .upsert(assets
            .map((asset) => {
                  "location": location ?? asset.location,
                  "purchase_cost": purchaseCost ?? asset.purchaseCost,
                  "purchase_date": (purchaseDate ?? asset.purchaseDate)
                      .toUtc()
                      .toIso8601String(),
                  "additional_cost": (additionalCost ?? asset.additionalCost).map((e) => e.toMap()).toList(),
                  "purchased_from": purchasedFrom ?? asset.purchasedFrom,
                  "custom_fields":
                      (customFields ?? asset.customFields).map((key, value) {
                    return MapEntry(key, value.getValue());
                  }),
                  "notes": notes ?? asset.notes,
                  "recovered_cost": recoveredCost ?? asset.recoveredCost,
                  "template": asset.template.id,
                  "id": asset.id,
                })
            .toList())
        .select());

    if (response == null) {
      throw DatabaseError();
    }

    await _insertHistory(
      assets: assets,
      challanId: challanId,
      challanType: challanType,
      location: location,
      purchaseCost: purchaseCost,
      purchaseDate: purchaseDate,
      additionalCost: List<AdditionalCost>.from(additionalCost ?? assets.first.additionalCost),
      purchasedFrom: purchasedFrom,
      customFields: Map.from(customFields ?? assets.first.customFields),
      notes: notes,
      recoveredCost: recoveredCost,
    );

    for (var element in response) {
      element["template"] = assets.first.template.toMap();
    }

    final updatedAssets = List<Asset>.from(response
        .map(
          (e) => Asset.fromMap(e),
        )
        .toList());

    for (var updatedAsset in updatedAssets) {
      this.assets[updatedAsset.uuid] = updatedAsset;
    }
    notifyListeners();
    return updatedAssets;
  }

  Future<void> _insertHistory({
    required List<Asset> assets,
    int? challanId,
    int? challanType,
    bool created = false,
    String? location,
    int? purchaseCost,
    DateTime? purchaseDate,
    List<AdditionalCost>? additionalCost,
    String? purchasedFrom,
    Map<String, FieldValue>? customFields,
    String? notes,
    int? recoveredCost,
  }) async {
    /*
    history.changes is like 
    {
        "custom_fields" : [
            {
                "fieldName": "name",
                "before": "before",
                "after": "after",
            },
        ],
        "fieldName": {
            "before": "before",
            "after": "after",
        }
    }
    */

    var asset = assets.first;
    var changes = {};

    (customFields ?? {}).removeWhere((key, value) {
      if (asset.customFields[key] == null) return true;
      return asset.customFields[key]!.value == value.value;
    });

    if (created) {
      changes["created"] = true;
    }

    if (location != null) {
      changes["location"] = {
        "before": asset.location,
        "after": location,
      };
    }

    if (purchaseCost != null) {
      changes["purchase_cost"] = {
        "before": asset.purchaseCost,
        "after": purchaseCost,
      };
    }

    if (purchaseDate != null) {
      changes["purchase_date"] = {
        "before": asset.purchaseDate.toUtc().toIso8601String(),
        "after": purchaseDate.toUtc().toIso8601String(),
      };
    }

    if (additionalCost != null && additionalCost.isNotEmpty) {
      changes["additional_cost"] = [];
      // If key is in new but not in asset, then it is a new field
      // If key is in asset but not in new, then it is a deleted field
      // If key is in both, then it is a changed field
      // Either name or value could be changed

      var newReasons = additionalCost.map((e) => e.reason).toSet();
      var oldReasons = asset.additionalCost.map((e) => e.reason).toSet();
      var addedReasons = newReasons.difference(oldReasons);
      var removedReasons = oldReasons.difference(newReasons);
      var commonReasons = newReasons.intersection(oldReasons);
      
      for (var reason in addedReasons) {
        changes["additional_cost"].add({
          "fieldName": reason,
          "before": null,
          "after": additionalCost.firstWhere((e) => e.reason == reason).amount,
        });
      }

      for (var reason in removedReasons) {
        changes["additional_cost"].add({
          "fieldName": reason,
          "before": asset.additionalCost.firstWhere((e) => e.reason == reason).amount,
          "after": null,
        });
      }

      // Ugly but, i dont see n growing past 10 lmao
      for (var reason in commonReasons) {
        if (asset.additionalCost.firstWhere((e) => e.reason == reason).amount == additionalCost.firstWhere((e) => e.reason == reason).amount) {
          continue;
        }
        changes["additional_cost"].add({
          "fieldName": reason,
          "before": asset.additionalCost.firstWhere((e) => e.reason == reason).amount,
          "after": additionalCost.firstWhere((e) => e.reason == reason).amount,
        });
      }
    }

    if (purchasedFrom != null) {
      changes["purchased_from"] = {
        "before": asset.purchasedFrom,
        "after": purchasedFrom,
      };
    }

    if (customFields != null && customFields.isNotEmpty) {
      changes["custom_fields"] = [];
      for (var key in customFields.keys) {
        changes["custom_fields"].add({
          "fieldName": key,
          "before": asset.customFields[key]?.getValue(),
          "after": customFields[key]?.getValue(),
        });
      }
    }

    if (notes != null) {
      changes["notes"] = {
        "before": asset.notes,
        "after": notes,
      };
    }

    if (recoveredCost != null) {
      changes["recovered_cost"] = {
        "before": asset.recoveredCost,
        "after": recoveredCost,
      };
    }

    var response = await _client
        .from("assets_history")
        .insert(assets
            .map((e) => {
                  "asset_uuid": e.uuid,
                  "changes": changes,
                  "challan_id": challanId,
                  "challan_type": challanType,
                })
            .toList())
        .select();

    if (response == null) {
      throw DatabaseError();
    }
    assetHistory.addAll(List<AssetHistory>.from(
        response.map((e) => AssetHistory.fromMap(e)).toList()));
    notifyListeners();
  }

  Future<void> deleteAsset({
    required Asset asset,
  }) async {
    // TODO check if asset is used in any challan
    await _client.from("assets").delete().eq("id", asset.id);
    assets.remove(asset.uuid);
    notifyListeners();
  }

  Future<InwardChallan> createInwardChallan({
    required int number,
    required String session,
    required DateTime createdAt,
    required Buyer buyer,
    required List<Product> products,
    required int productsValue,
    required String receivedBy,
    required String vehicleNumber,
    required String notes,
  }) async {
    final response = await _client.from("inward_challans").insert({
      "number": number,
      "session": session,
      "created_at": createdAt.toUtc().toIso8601String(),
      "buyer": buyer.toMap(),
      "products": products.map((e) => e.toMap()).toList(),
      "products_value": productsValue,
      "received_by": receivedBy.toUpperCase(),
      "vehicle_number": vehicleNumber.toUpperCase(),
      "notes": notes,
    }).select();

    if (response == null) {
      throw DatabaseError();
    }

    var rawInwardChallan = response[0];
    for (var i = 0; i < (rawInwardChallan["products"] as List).length; i++) {
      var rawProduct = rawInwardChallan["products"][i];
      if (rawProduct["assets"] != null) {
        // That means it contains asset ids, replace them with actual assets
        rawProduct["assets"] =
            rawProduct["assets"].map((assetId) => assets[assetId]).toList();
      }
    }

    final inwardChallan = InwardChallan.fromMap(rawInwardChallan);
    inwardChallans.insert(0, inwardChallan);
    notifyListeners();
    return inwardChallan;
  }

  Future<void> updateInwardChallan({
    required InwardChallan inwardChallan,
    int? number,
    String? session,
    DateTime? createdAt,
    Buyer? buyer,
    List<Product>? products,
    int? productsValue,
    String? receivedBy,
    String? vehicleNumber,
    String? notes,
    bool? cancelled,
  }) async {
    if (number == null &&
        session == null &&
        createdAt == null &&
        buyer == null &&
        products == null &&
        productsValue == null &&
        receivedBy == null &&
        vehicleNumber == null &&
        notes == null &&
        cancelled == null) {
      return;
    }

    await _client.from("inward_challans").update({
      "number": number ?? inwardChallan.number,
      "session": session ?? inwardChallan.session,
      "created_at": createdAt?.toUtc().toIso8601String() ??
          inwardChallan.createdAt.toUtc().toIso8601String(),
      "buyer": (buyer ?? inwardChallan.buyer).toMap(),
      "products": (products ?? inwardChallan.products)
          .map(
            (e) => e.toMap(),
          )
          .toList(),
      "products_value": productsValue ?? inwardChallan.productsValue,
      "received_by": receivedBy?.toUpperCase() ?? inwardChallan.receivedBy,
      "vehicle_number":
          vehicleNumber?.toUpperCase() ?? inwardChallan.vehicleNumber,
      "notes": notes ?? inwardChallan.notes,
      "cancelled": cancelled ?? inwardChallan.cancelled,
    }).eq("id", inwardChallan.id);

    inwardChallans = inwardChallans.map((e) {
      if (e.id == inwardChallan.id) {
        return InwardChallan(
          id: e.id,
          number: number ?? e.number,
          session: session ?? e.session,
          createdAt: createdAt ?? e.createdAt,
          buyer: buyer ?? e.buyer,
          products: products ?? e.products,
          productsValue: productsValue ?? e.productsValue,
          receivedBy: receivedBy?.toUpperCase() ?? e.receivedBy,
          vehicleNumber: vehicleNumber?.toUpperCase() ?? e.vehicleNumber,
          notes: notes ?? e.notes,
          cancelled: cancelled ?? e.cancelled,
        );
      }
      return e;
    }).toList();
  }

  Future<void> deleteHistory(
    List<Asset> assets,
    int challanId,
    int challanType,
  ) async {
    var response = await _client
        .from("assets_history")
        .delete()
        .eq("challan_id", challanId)
        .eq("challan_type", challanType)
        .in_(
            "asset_uuid",
            assets
                .map(
                  (e) => e.uuid,
                )
                .toList())
        .select();

    if (response == null) {
      throw DatabaseError();
    }

    for (var deletedHistory in response) {
      assetHistory.removeWhere((element) => element.id == deletedHistory["id"]);
    }
  }
}

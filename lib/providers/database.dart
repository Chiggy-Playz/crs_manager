import 'package:flutter/foundation.dart';
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
        .map((e) => Challan.fromMap(e))
        .toList();

    // Load rest of the challans in background
    loadChallans(challanPageCount);

    secrets =
        (await _client.from("secrets").select<List<Map<String, dynamic>>>())
            .asMap()
            .map((index, row) => MapEntry(row["name"], row["value"]));

    templates =
        (await _client.from("templates").select<List<Map<String, dynamic>>>())
            .map(
              (e) => Template.fromMap(e),
            )
            .toList();

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
          .map((e) => Challan.fromMap(e))
          .toList();
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

  Future<List<Buyer>> getBuyers() async {
    return buyers;
  }

  Future<Buyer> createBuyer(
      {required String name,
      required String address,
      required String gst,
      required String state}) async {
    final response = await _client.from("buyers").insert({
      "name": name.toUpperCase(),
      "address": address.toUpperCase(),
      "gst": gst.toUpperCase(),
      "state": state.toUpperCase(),
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
  }) async {
    if (name == null && address == null && gst == null && state == null) {
      return;
    }

    await _client.from("buyers").update({
      "name": name?.toUpperCase() ?? buyer.name,
      "address": address?.toUpperCase() ?? buyer.address,
      "gst": gst?.toUpperCase() ?? buyer.gst,
      "state": state?.toUpperCase() ?? buyer.state
    }).eq("id", buyer.id);

    buyers = buyers.map((e) {
      if (e.id == buyer.id) {
        return Buyer(
            id: e.id,
            name: name?.toUpperCase() ?? e.name,
            address: address?.toUpperCase() ?? e.address,
            gst: gst?.toUpperCase() ?? e.gst,
            state: state?.toUpperCase() ?? e.state);
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
    final challan = Challan.fromMap(response[0]);
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
          filteredChallans = filteredChallans.where((challan) {
            return condition.value.start.isBefore(challan.createdAt) &&
                condition.value.end.isAfter(challan.createdAt);
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

  Future<Template> createTemplate(
      {required String name, required List<Field> fields}) async {
    final response = await _client.from("templates").insert({
      "name": name,
      "fields": fields.map((e) => e.toMap()).toList(),
    }).select();

    if (response == null) {
      throw DatabaseError();
    }

    final template = Template.fromMap(response[0]);
    templates.add(template);
    notifyListeners();
    return template;
  }

  Future<Template> updateTemplate(
      {required Template template, String? name, List<Field>? fields}) async {
    if (name == null && fields == null) {
      return template;
    }

    await _client.from("templates").update({
      "name": name ?? template.name,
      "fields": fields?.map((e) => e.toMap()).toList() ?? template.fields,
    }).eq("id", template.id);

    templates = templates.map((e) {
      if (e.id == template.id) {
        return Template(
          id: e.id,
          name: name ?? e.name,
          fields: fields ?? e.fields,
        );
      }
      return e;
    }).toList();

    notifyListeners();
    return Template(
      id: template.id,
      name: name ?? template.name,
      fields: fields ?? template.fields,
    );
  }
}

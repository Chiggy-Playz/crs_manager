import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/buyer.dart';
import '../models/challan.dart';
import '../utils/exceptions.dart';

class DatabaseModel extends ChangeNotifier {
  List<Buyer> buyers = [];
  List<Challan> challans = [];

  late SupabaseClient _client;
  bool connected = false;

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
    loadCache();
  }

  Future<void> loadCache() async {
    buyers = (await _client
            .from("buyers")
            .select<List<Map<String, dynamic>>>()
            .order("name", ascending: true))
        .map((e) => Buyer.fromMap(e))
        .toList();

    challans = (await _client
            .from("challans")
            .select<List<Map<String, dynamic>>>()
            .order("created_at"))
        .map((e) => Challan.fromMap(e))
        .toList();

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
      "name": name,
      "address": address,
      "gst": gst,
      "state": state
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
      "name": name ?? buyer.name,
      "address": address ?? buyer.address,
      "gst": gst ?? buyer.gst,
      "state": state ?? buyer.state
    }).eq("id", buyer.id);

    buyers = buyers.map((e) {
      if (e.id == buyer.id) {
        return Buyer(
            id: e.id,
            name: name ?? e.name,
            address: address ?? e.address,
            gst: gst ?? e.gst,
            state: state ?? e.state);
      }
      return e;
    }).toList();

    notifyListeners();
  }

  Future<void> deleteBuyer(Buyer buyer) async {
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
                .limit(1))
            .first["number"] ??
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
      "delivered_by": deliveredBy,
      "vehicle_number": vehicleNumber,
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
    String? deliveredBy,
    String? vehicleNumber,
    String? notes,
    bool? received,
    bool? digitallySigned,
    bool? cancelled,
  }) async {
    if (buyer == null &&
        products == null &&
        productsValue == null &&
        deliveredBy == null &&
        vehicleNumber == null &&
        notes == null &&
        received == null &&
        digitallySigned == null &&
        cancelled == null) {
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
          "delivered_by": deliveredBy ?? challan.deliveredBy,
          "vehicle_number": vehicleNumber ?? challan.vehicleNumber,
          "notes": notes ?? challan.notes,
          "received": received ?? challan.received,
          "digitally_signed": digitallySigned ?? challan.digitallySigned,
          "cancelled": cancelled ?? challan.cancelled,
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
            deliveredBy: deliveredBy ?? e.deliveredBy,
            vehicleNumber: vehicleNumber ?? e.vehicleNumber,
            notes: notes ?? e.notes,
            received: received ?? e.received,
            digitallySigned: digitallySigned ?? e.digitallySigned,
            cancelled: cancelled ?? e.cancelled);
      }
      return e;
    }).toList();
    notifyListeners();
  }
}

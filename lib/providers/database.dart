import 'package:crs_manager/models/buyer.dart';
import 'package:crs_manager/utils/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef ListOfDicts = List<Map<String, dynamic>>;

class DatabaseModel extends ChangeNotifier {
  List<Buyer> buyers = [];

  late SupabaseClient _client;
  bool connected = false;

  Future<void> _loadCache() async {
    buyers = (await _client
            .from("buyers")
            .select<List<Map<String, dynamic>>>()
            .order("name", ascending: true))
        .map((e) => Buyer.fromMap(e))
        .toList();
    notifyListeners();
  }

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
    _loadCache();
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
}

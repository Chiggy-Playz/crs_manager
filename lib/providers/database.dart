import 'package:crs_manager/models/buyer.dart';
import 'package:crs_manager/utils/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef ListOfDicts = List<Map<String, dynamic>>;

class DatabaseModel extends ChangeNotifier {
  List<Buyer> buyers = [];

  late SupabaseClient _client;

  Future<void> _loadCache() async {
    buyers = (await _client.from("buyers").select<List<Map<String, dynamic>>>()).map((e) => Buyer.fromMap(e)).toList()..sort((a, b) => a.name.compareTo(b.name),);
    notifyListeners();
  }

  Future<void> connect(String host, String key) async {
    try {
    // Try to connect
    await Supabase.initialize(
      url: host,
      anonKey: key,
    );

    // Check if the connection is valid by fetching a single row from the models table
    // The models table will always have 1 row
    
      await Supabase.instance.client.from("models").select().limit(1);
    } catch (err) {
      Supabase.instance.dispose();
      throw DatabaseConnectionError();
    }

    _client = Supabase.instance.client;
    _loadCache();
  }

  Future<List<Buyer>> getBuyers() async {
    return buyers;
  }
}

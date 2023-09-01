import 'dart:io';

import 'package:crs_manager/providers/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../../models/asset.dart';

class TransactionRow {
  DateTime when;
  int? challanNumber;
  String? challanSession;
  String name;
  int inflow = 0;
  int outflow = 0;
  int get balance => inflow - outflow;

  TransactionRow({
    required this.when,
    this.challanNumber,
    this.challanSession,
    required this.name,
    required this.inflow,
    required this.outflow,
  });
}

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, required this.assets});

  final List<Asset> assets;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<TransactionRow> transactionRows = [];

  @override
  void initState() {
    super.initState();
    // _landscapeOrientation();
    _prepareData();
  }

  @override
  dispose() {
    _resetOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (transactionRows.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return const Placeholder();
  }

  void _prepareData() {
    final db = Provider.of<DatabaseModel>(context, listen: false);
    var assets = {for (var e in widget.assets) e.uuid: e};
    List<AssetHistory> allAssetHistory = [];
    // First, fetch ALL history for each asset
    for (var asset in assets.values) {
      for (var assetHistory in db.assetHistory) {
        if (assetHistory.assetUuid == asset.uuid &&
            (assetHistory.changes.containsKey("location") ||
                assetHistory.changes.containsKey("created"))) {
          allAssetHistory.add(assetHistory);
        }
      }
    }

    // Then, sort the history by date, oldest to newest
    allAssetHistory.sort((a, b) => a.when.compareTo(b.when));

    // Group assetHistory by changes
    Map<String, List<AssetHistory>> groupedAssetHistory = {};

    Map<String, dynamic> previousChanges = {};
    final DeepCollectionEquality deepCollectionEquality =
        DeepCollectionEquality();
    TransactionRow transactionRow = TransactionRow(
      when: allAssetHistory.first.when,
      name: "Opening Balance",
      inflow: 0,
      outflow: 0,
    );

    for (var assetHistory in allAssetHistory) {
      var newChanges = assetHistory.changes;
      transactionRow.when = assetHistory.when;

      // Means that the changes are not the same as the previous changes
      if (!deepCollectionEquality.equals(previousChanges, newChanges)) {
        if (transactionRow.inflow != 0 || transactionRow.outflow != 0) {
          transactionRows.add(transactionRow);
        }
        transactionRow = TransactionRow(
          when: assetHistory.when,
          name: "",
          inflow: 0,
          outflow: 0,
        );
      }

      if (newChanges.containsKey("created")) {
        transactionRow.name = "Opening Balance";
        transactionRow.inflow += 1;
      } else {
        // Location change
        var location = newChanges["location"]!;
        // Inwards
        if (location["after"] == "Office") {
          transactionRow.inflow += 1;
          transactionRow.name = location["before"];
        } else {
          // Outwards
          transactionRow.outflow += 1;
          transactionRow.name = location["after"];
        }
      }
      previousChanges = newChanges;
    }
    if (transactionRow.inflow != 0 || transactionRow.outflow != 0) {
      transactionRows.add(transactionRow);
    }

    if (transactionRows.isEmpty) {
      return;
    }

    setState(() {});
  }

  void _resetOrientation() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _landscapeOrientation() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }
}

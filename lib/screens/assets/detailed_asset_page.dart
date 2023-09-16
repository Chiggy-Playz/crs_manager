import 'dart:io';

import 'package:crs_manager/models/challan.dart';
import 'package:crs_manager/models/inward_challan.dart';
import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/challans/challan_pageview.dart';
import 'package:crs_manager/screens/challans/inward/inward_challan_page.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:crs_manager/utils/template_string.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/asset.dart';

class TransactionRow {
  DateTime when;
  ChallanBase? challan;
  String name;
  int inflow = 0;
  int outflow = 0;
  int get balance => inflow - outflow;

  TransactionRow({
    required this.when,
    this.challan,
    required this.name,
    required this.inflow,
    required this.outflow,
  });
}

final columns = [
  "Date",
  "Challan No.",
  "Name",
  "In",
  "Out",
  "Balance",
];

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, required this.assets});

  final List<Asset> assets;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<TransactionRow> transactionRows = [];
  String assetDescription = "";
  List<String> buyerFilter = [];
  Map<String, int> buyerBalance = {};

  @override
  void initState() {
    super.initState();
    _landscapeOrientation();
    var asset = widget.assets.first;
    assetDescription =
        TemplateString(asset.template.metadata).format(asset.rawCustomFields);
    _prepareData();
    for (var asset in widget.assets) {
      buyerBalance[asset.location] = (buyerBalance[asset.location] ?? 0) + 1;
    }
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
    return Scaffold(
      appBar: TransparentAppBar(
        title: Text(assetDescription),
        actions: [
          IconButton(
            onPressed: filterPressed,
            icon: const Icon(Icons.filter_alt),
          )
        ],
      ),
      body: Scrollbar(
        thickness: 10,
        interactive: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Column(
                  children: [
                    SizedBox(
                        // height: 40 * 100.h,
                        width: 1.2 * 100.w,
                        child: Table(
                          columnWidths: const {
                            2: FlexColumnWidth(1.0), // Name
                            5: FlexColumnWidth(0.5), // Balance
                          },
                          border: TableBorder.all(
                            color: Theme.of(context).colorScheme.onBackground,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                          children: _getBuyerRows(),
                        )),
                    Padding(
                      padding: EdgeInsets.all(2.h),
                      child: Text("Transaction History",
                          style: Theme.of(context).textTheme.displayMedium),
                    ),
                    SizedBox(
                        // height: 40 * 100.h,
                        width: 1.2 * 100.w,
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(0.3), // Date
                            1: FlexColumnWidth(0.3), // Challan No.
                            2: FlexColumnWidth(1.0), // Name
                            3: FlexColumnWidth(0.2), // Inflow
                            4: FlexColumnWidth(0.2), // Outflow
                            5: FlexColumnWidth(0.2), // Balance
                          },
                          border: TableBorder.all(
                            color: Theme.of(context).colorScheme.onBackground,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                          children: _getRows(),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TableRow> _getRows() {
    List<TableRow> rows = [];
    // Header Row
    rows.add(TableRow(
        children: columns
            .map((columnName) => Center(
                  child: Text(
                    columnName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ))
            .toList()));

    // Add rows for transactions
    int previousBalance = 0;
    for (var transactionRow in transactionRows) {
      if (buyerFilter.isNotEmpty &&
          !buyerFilter.contains(transactionRow.name)) {
        continue;
      }

      previousBalance += transactionRow.balance;

      var challan = transactionRow.challan;
      var session = challan?.session
          .toString()
          .split("-")
          .map((e) => e.substring(2))
          .join("-");

      rows.add(TableRow(
        children: [
          Center(
            child: Text(formatterDate.format(transactionRow.when)),
          ),
          Center(
            child: GestureDetector(
              onTap: () => onChallanTap(transactionRow.challan),
              child: Text(
                transactionRow.challan == null
                    ? ""
                    : "${transactionRow.challan is InwardChallan ? 'In' : 'Out'} "
                        "${transactionRow.challan!.number} / "
                        "$session",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(transactionRow.name),
          ),
          Center(
            child: Text(
              "${transactionRow.inflow}",
              style: transactionRow.inflow == 0
                  ? null
                  : TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ),
          Center(
            child: Text(
              "${transactionRow.outflow}",
              style: transactionRow.outflow == 0
                  ? null
                  : TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
            ),
          ),
          Center(
            child: Text(
              (previousBalance).toString(),
            ),
          ),
        ],
      ));
    }
    return rows;
  }

  List<TableRow> _getBuyerRows() {
    List<TableRow> rows = [];

    // Header Row
    rows.add(
      const TableRow(
        children: [
          Center(
            child: Text(
              "Buyer",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              "Balance",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    rows.add(TableRow(
      children: [
        const Center(
          child: Text(
            "Office",
          ),
        ),
        Center(
          child: Text(
            (buyerBalance["Office"] ?? 0).toString(),
          ),
        ),
      ],
    ));

    for (var buyer in buyerBalance.keys.sorted(
      (a, b) => a.compareTo(b),
    )) {
      if (buyer == "Office") continue;
      rows.add(
        TableRow(
          children: [
            Center(
              child: Text(
                buyer,
              ),
            ),
            Center(
              child: Text(
                buyerBalance[buyer]!.toString(),
              ),
            ),
          ],
        ),
      );
    }

    // Total row
    rows.add(TableRow(children: [
      const Center(
        child: Text(
          "Total",
        ),
      ),
      Center(
        child: Text(
          widget.assets.length.toString(),
        ),
      ),
    ]));

    return rows;
  }

  // challan can be either Challan or InwardChallan or null
  void onChallanTap(var challan) async {
    if (challan == null) return;
    _resetOrientation();
    if (challan is Challan) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChallanPageView(
            challans: [challan],
            initialIndex: 0,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InwardChallanPage(
            inwardChallan: challan,
          ),
        ),
      );
    }

    _landscapeOrientation();
  }

  void filterPressed() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            titlePadding: const EdgeInsets.only(top: 24.0, bottom: 0),
            contentPadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            title: const Column(
              children: [
                Text("Filter by buyer"),
                Divider(),
              ],
            ),
            content: SingleChildScrollView(
                child: Column(
              children: buyerBalance.keys
                  .sorted((a, b) => a.compareTo(b))
                  .map((e) => CheckboxListTile(
                        title: Text(e),
                        value: buyerFilter.contains(e),
                        onChanged: (value) {
                          if (value == true) {
                            buyerFilter.add(e);
                          } else {
                            buyerFilter.remove(e);
                          }
                          setState(() {});
                        },
                      ))
                  .toList(),
            )),
            actions: [
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        buyerFilter.clear();
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      child: const Text("Clear"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() {});
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

    Map<String, dynamic> previousChanges = {};
    int previousChallanId = -1;
    int previousChallanType = -1;
    const DeepCollectionEquality deepCollectionEquality =
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
      if (!deepCollectionEquality.equals(previousChanges, newChanges) ||
          ((assetHistory.challanId != null) &&
              ((previousChallanId != assetHistory.challanId) &&
                  (previousChallanType == assetHistory.challanType!.index)))) {
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

        if (assetHistory.challanId != null) {
          if (assetHistory.challanType == ChallanType.outward) {
            transactionRow.challan = db.challans
                .firstWhere((element) => element.id == assetHistory.challanId);
          } else {
            transactionRow.challan = db.inwardChallans
                .firstWhere((element) => element.id == assetHistory.challanId);
          }
        }
      }
      previousChanges = newChanges;
      if (assetHistory.challanId != null) {
        previousChallanId = assetHistory.challanId!;
        previousChallanType = assetHistory.challanType!.index;
      }
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

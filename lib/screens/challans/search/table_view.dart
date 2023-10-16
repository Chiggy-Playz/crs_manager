import 'dart:io';

import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/challans/challan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../../../models/buyer.dart';
import '../../../models/challan.dart';
import '../../../utils/constants.dart';

final columns = [
  "Date",
  "Challan No.",
  "Description",
  "Qty",
  "Serial",
  "Bill No.",
  "Additional Description",
  "Notes",
];

class TableViewPage extends StatefulWidget {
  const TableViewPage({super.key, required this.challans});

  final List<Challan> challans;

  @override
  State<TableViewPage> createState() => _TableViewPageState();
}

class _TableViewPageState extends State<TableViewPage> {
  List<Challan> challans = [];
  Map<Buyer, List<Challan>> challansSortedByBuyer = {};
  List<Buyer> buyersSortedByName = [];

  @override
  void initState() {
    super.initState();

    _landscapeOrientation();
    challans = widget.challans;
    _prepareData();
  }

  @override
  dispose() {
    _resetOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            onPressed: _exportIndex,
          ),
        ],
      ),
      body: Scrollbar(
        thickness: 10,
        interactive: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 100 * 100.w,
              width: 1.2 * 100.w,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(0.7), // Date
                  1: FlexColumnWidth(0.7), // Challan No.
                  2: FlexColumnWidth(1.5), // Description
                  3: FlexColumnWidth(0.5), // Qty
                  4: FlexColumnWidth(1), // Serial
                  5: FlexColumnWidth(0.3), // Bill No.
                  6: FlexColumnWidth(1), // Additional Description
                  7: FlexColumnWidth(1), // Notes
                },
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.onBackground,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                children: _getRows(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TableRow> _getRows() {
    var rows = <TableRow>[];

    // Header Row

    rows.add(
      TableRow(
        children: columns
            .map((column) => Center(
                    child: Text(
                  column,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )))
            .toList(),
      ),
    );

    challansSortedByBuyer.forEach((buyer, buyerChallans) {
      // Add row for buyer
      rows.add(
        TableRow(
          decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.tertiary),
          children: [
            const Text(""),
            const Text(""),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Center(
                child: Text(
                  buyer.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiary),
                ),
              ),
            ),
            const Text(""),
            const Text(""),
            const Text(""),
            const Text(""),
            const Text(""),
          ],
        ),
      );

      // Add  rows for challans products

      for (Challan challan in buyerChallans) {
        for (Product product in challan.products) {
          var cancelledStyle = challan.cancelled
              ? TextStyle(color: Theme.of(context).colorScheme.onError)
              : null;
          rows.add(
            TableRow(
              decoration: challan.cancelled
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                    )
                  : null,
              children: [
                Center(
                    child: Text(
                  formatterDate.format(challan.createdAt),
                  style: cancelledStyle,
                )),
                Center(
                  child: Text(
                    "${challan.number} / ${challan.session.split("-").map((e) => e.replaceFirst("20", "")).join("-")}",
                    style: cancelledStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    product.description,
                    style: cancelledStyle,
                  ),
                ),
                Center(
                  child: Text(
                    "${product.quantity} ${product.quantityUnit}",
                    style: cancelledStyle,
                  ),
                ),
                Center(
                    child: Text(
                  product.serial,
                  style: cancelledStyle,
                )),
                Center(
                    child: Text(
                  challan.billNumber?.toString() ?? "",
                  style: cancelledStyle,
                )),
                Center(
                    child: Text(
                  product.additionalDescription,
                  style: cancelledStyle,
                )),
                Center(
                    child: Text(
                  challan.notes,
                  style: cancelledStyle,
                )),
              ].map((e) {
                return GestureDetector(
                    child: e,
                    onTap: () async {
                      _resetOrientation();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChallanPage(
                            challan: challan,
                          ),
                        ),
                      );
                      _landscapeOrientation();
                      challans = challans.map((e) {
                        if (e.id != challan.id) {
                          return e;
                        }

                        return Provider.of<DatabaseModel>(context,
                                listen: false)
                            .challans
                            .firstWhere((element) => element.id == challan.id);
                      }).toList();
                      setState(() {
                        _prepareData();
                      });
                    });
              }).toList(),
            ),
          );
        }
      }
    });

    return rows;
  }

  void _exportCsv() async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Write header row
    for (int i = 0; i < columns.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(columns[i]);
    }

    // Write data rows
    int row = 2;
    challansSortedByBuyer.forEach((buyer, buyerChallans) {
      sheet.getRangeByIndex(row, 1, row, 8).merge();
      sheet.getRangeByIndex(row, 1).setText(buyer.name);
      sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#e0e0e0';

      row++;

      for (Challan challan in buyerChallans) {
        bool cancelled = challan.cancelled;
        for (Product product in challan.products) {
          sheet
              .getRangeByIndex(row, 1)
              .setText(formatterDate.format(challan.createdAt));
          sheet.getRangeByIndex(row, 2).setText(
              "${challan.number} / ${challan.session.split("-").map((e) => e.replaceFirst("20", "")).join("-")}");
          sheet.getRangeByIndex(row, 3).setText(product.description);
          sheet
              .getRangeByIndex(row, 4)
              .setText("${product.quantity} ${product.quantityUnit}");
          sheet.getRangeByIndex(row, 5).setText(product.serial);
          sheet
              .getRangeByIndex(row, 6)
              .setText(challan.billNumber?.toString() ?? "");
          sheet.getRangeByIndex(row, 7).setText(product.additionalDescription);
          sheet.getRangeByIndex(row, 8).setText(challan.notes);

          if (cancelled) {
            sheet.getRangeByIndex(row, 1, row, 8).cellStyle.backColor =
                '#ff0000';
          }
          row++;
        }
      }
    });

    final List<int> bytes = workbook.saveAsStream();
    var directory = await getApplicationDocumentsDirectory();
    // Create file is path available otherwise add 1,2,3 etc to the file name

    File file = File("${directory.path}/search.xlsx");
    if (await file.exists()) {
      int i = 1;
      while (await file.exists()) {
        file = File("${directory.path}/search$i.xlsx");
        i++;
      }
    }

    file
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    workbook.dispose();

    OpenFile.open(file.path);
  }

  void _exportIndex() async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    var columns = [
      "S. No",
      "Date",
      "Challan No.",
      "Buyer",
    ];

    // Write header row
    for (int i = 0; i < columns.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(columns[i]);
    }

    // Write data rows for challans sorted by date, earliest first
    int row = 2;
    var dateSortedChallans = List.from(challans)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (Challan challan in dateSortedChallans) {
      sheet.getRangeByIndex(row, 1).setText((row - 1).toString());
      sheet
          .getRangeByIndex(row, 2)
          .setText(formatterDate.format(challan.createdAt));
      sheet.getRangeByIndex(row, 3).setText(
          "${challan.number} / ${challan.session.split("-").map((e) => e.replaceFirst("20", "")).join("-")}");
      sheet.getRangeByIndex(row, 4).setText(challan.buyer.name);
      row++;
    }

    final List<int> bytes = workbook.saveAsStream();
    var directory = await getApplicationDocumentsDirectory();

    File file = File("${directory.path}/index.xlsx");
    if (await file.exists()) {
      int i = 1;
      while (await file.exists()) {
        file = File("${directory.path}/index$i.xlsx");
        i++;
      }
    }

    file
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    workbook.dispose();

    OpenFile.open(file.path);
  }

  void _prepareData() {
    challansSortedByBuyer = {};
    challans.sort(
      (a, b) => a.buyer.name.compareTo(b.buyer.name),
    );
    for (Challan challan in challans) {
      challansSortedByBuyer
          .putIfAbsent(challan.buyer, () => <Challan>[])
          .add(challan);
    }
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

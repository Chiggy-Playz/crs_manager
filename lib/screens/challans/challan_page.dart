import 'dart:io';
import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/buyer.dart';
import '../../providers/database.dart';
import '../../models/challan.dart';
import '../../utils/exceptions.dart';
import '../../utils/extensions.dart';
import '../../utils/widgets.dart';
import '../buyers/choose_buyer.dart';
import '../loading.dart';

import 'get_pdf.dart';
import 'product_page.dart';

final formatter = DateFormat("dd-MMMM-y");

class ChallanPage extends StatefulWidget {
  const ChallanPage({super.key, this.challan});

  final Challan? challan;

  @override
  State<ChallanPage> createState() => _ChallanPageState();
}

class _ChallanPageState extends State<ChallanPage> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? nextChallanInfo;

  Buyer? _buyer;
  List<Product> _products = [];
  int _productsValue = 0;
  String _deliveredBy = "";
  String _vehicleNumber = "";
  String _notes = "";
  bool _received = false;
  bool _cancelled = false;
  bool _digitallySigned = false;

  @override
  void initState() {
    if (widget.challan != null) {
      _buyer = widget.challan!.buyer;
      _products = List.from(widget.challan!.products);
      _productsValue = widget.challan!.productsValue;
      _deliveredBy = widget.challan!.deliveredBy;
      _vehicleNumber = widget.challan!.vehicleNumber;
      _notes = widget.challan!.notes;
      _received = widget.challan!.received;
      _cancelled = widget.challan!.cancelled;
      _digitallySigned = widget.challan!.digitallySigned;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: Text(widget.challan == null ? "New Challan" : "Edit Challan"),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.article),
            itemBuilder: (context) => List.generate(
              3,
              (index) => PopupMenuItem(
                value: index + 1,
                child: Text("${index + 1} Page"),
              ),
            ),
            onSelected: (value) => viewPdf(value),
          ),
          if (widget.challan is Challan)
            InkWell(
              onLongPress: _cancelled ? () {} : onCancelPressed,
              onTap: _cancelled
                  ? null
                  : () =>
                      context.showSnackBar(message: "Hold to cancel challan"),
              child: cup.Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<DatabaseModel>(
        builder: (context, value, child) {
          return widget.challan == null
              ? FutureBuilder(
                  future: value.getNextChallanInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      nextChallanInfo = snapshot.data as Map<String, dynamic>;
                      return actualPage();
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                )
              : actualPage();
        },
      ),
    );
  }

  Widget actualPage() {
    var bodyTextTheme = Theme.of(context).textTheme.titleLarge;

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SpacedRow(
                  widget1: Text("Challan Number", style: bodyTextTheme),
                  widget2: Text(
                      "${nextChallanInfo?["number"] ?? widget.challan!.number} (${nextChallanInfo?["session"] ?? widget.challan!.session})",
                      style: bodyTextTheme),
                ),
                SizedBox(height: 2.h),
                SpacedRow(
                  widget1: Text(
                    "Date",
                    style: bodyTextTheme,
                  ),
                  widget2: Text(
                    formatter.format(widget.challan == null
                        ? DateTime.now()
                        : widget.challan!.createdAt),
                    style: bodyTextTheme,
                  ),
                ),
                SizedBox(height: 2.h),
                Card(
                  elevation: 12,
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text(
                      "Buyer",
                    ),
                    subtitle: Text(_buyer == null
                        ? "Click to choose a buyer"
                        : _buyer!.name),
                    onTap: _cancelled
                        ? null
                        : () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  ChooseBuyer(onBuyerSelected: onBuyerSelected),
                            ));
                          },
                    minLeadingWidth: 0,
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                SizedBox(
                  height: 45.h,
                  width: double.infinity,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: Column(
                        children: [
                          Text(
                            "Products",
                            style: bodyTextTheme,
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                return productCard(index);
                              },
                            ),
                          ),
                          SizedBox(height: 2.h),
                          FloatingActionButton.extended(
                            onPressed: _cancelled ? null : onAddProduct,
                            label: const Text("Add Product"),
                            icon: const Icon(Icons.add),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  enabled: !_cancelled,
                  decoration:
                      const InputDecoration(labelText: "Products Value"),
                  initialValue: widget.challan?.productsValue.toString() ?? "0",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Field cannot be empty";
                    }
                    if (int.tryParse(value) == null) {
                      return "Invalid value";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  onSaved: (newValue) => _productsValue = int.parse(newValue!),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  enabled: !_cancelled,
                  decoration: const InputDecoration(labelText: "Delivered By"),
                  initialValue: widget.challan?.deliveredBy ?? "None",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Field cannot be empty";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _deliveredBy = value;
                  }),
                  onSaved: (newValue) => _deliveredBy = newValue!,
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  enabled: !_cancelled,
                  decoration:
                      const InputDecoration(labelText: "Vehicle Number"),
                  initialValue: widget.challan?.vehicleNumber ?? "None",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Field cannot be empty";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _vehicleNumber = value;
                  }),
                  onSaved: (newValue) => _vehicleNumber = newValue!,
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  enabled: !_cancelled,
                  decoration: const InputDecoration(labelText: "Notes"),
                  initialValue: widget.challan?.notes ?? "",
                  validator: (value) {
                    if (value == null) {
                      return "Field cannot be empty";
                    }
                    return null;
                  },
                  maxLines: null,
                  onChanged: (value) => setState(() {
                    _notes = value;
                  }),
                  onSaved: (newValue) => _notes = newValue!,
                ),
                SizedBox(height: 2.h),
                SwitchListTile(
                  value: _received,
                  onChanged: _cancelled
                      ? null
                      : (value) => setState(() {
                            _received = value;
                          }),
                  title: const Text("Received"),
                  secondary: const Icon(Icons.arrow_downward),
                ),
                SizedBox(height: 2.h),
                SwitchListTile(
                  value: _digitallySigned,
                  onChanged: _cancelled
                      ? null
                      : (value) => setState(() {
                            _digitallySigned = value;
                          }),
                  title: const Text("Digitally Signed"),
                  secondary: const Icon(cup.CupertinoIcons.signature),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  height: 8.h,
                  width: 46.w,
                  child: ElevatedButton.icon(
                    onPressed: _cancelled ? null : () => saveChanges(),
                    icon: const Icon(Icons.save),
                    label: Text(
                      widget.challan == null ? "Create" : "Update",
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                SizedBox(height: 25.h)
              ],
            ),
          ),
        ),
      ),
    );
  }

  void viewPdf(int pages) async {
    Challan challan;
    try {
      challan = Challan(
        id: widget.challan?.id ?? -1,
        number: nextChallanInfo?['number'] ?? widget.challan!.number,
        session: nextChallanInfo?['session'] ?? widget.challan!.session,
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        deliveredBy: _deliveredBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
        received: _received,
        digitallySigned: _digitallySigned,
        cancelled: _cancelled,
        createdAt: widget.challan?.createdAt ?? DateTime.now(),
      );
    } catch (e) {
      context.showErrorSnackBar(
          message: "Incomplete challan. Please fill all the fields");
      return;
    }

    String path;

    try {
      path = await makePdf(challan, pages);
    } on PermissionDenied {
      context.showErrorSnackBar(message: "Permission denied");
      return;
    } catch (e) {
      context.showErrorSnackBar(
          message: "Error occured while trying to create pdf");
      return;
    }
    await Future.delayed(const Duration(milliseconds: 50));
    if (!await File(path).exists()) {
      if (!mounted) return;
      // Should never happen, but here we are :husk:
      context.showErrorSnackBar(message: "File not found");
      return;
    }

    if (Platform.isAndroid) {
      await OpenFile.open(path);
    } else {
      // Else we're on windows, and we just rely on browsers being able to open pdfs
      Uri url = Uri.file(path, windows: true);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (!mounted) return;
        context.showErrorSnackBar(message: "Couldn't open file");
      }
    }
  }

  void onCancelPressed() async {
    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Challan?"),
        content: const Text("Are you sure you want to cancel this challan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (result == null || result == false) return;
    if (!mounted) return;

    // Confirm again, just to be REALLY sure
    var secondResult = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Challan?"),
        content:
            const Text("Are you REALLY sure you want to cancel this challan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (secondResult == true) {
      await Provider.of<DatabaseModel>(context, listen: false)
          .updateChallan(challan: widget.challan!, cancelled: true);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    if (_buyer == null) {
      context.showErrorSnackBar(message: "Please select a buyer");
      return;
    }
    if (_products.isEmpty) {
      context.showErrorSnackBar(message: "Please add at least one product");
      return;
    }

    Navigator.of(context).push(opaquePage(const LoadingPage()));
    String action = "";
    if (widget.challan == null) {
      action = "created";
      await Provider.of<DatabaseModel>(context, listen: false).createChallan(
          number: nextChallanInfo!["number"],
          session: nextChallanInfo!["session"],
          buyer: _buyer!,
          products: _products,
          productsValue: _productsValue,
          deliveredBy: _deliveredBy,
          vehicleNumber: _vehicleNumber,
          notes: _notes,
          received: _received,
          digitallySigned: _digitallySigned);
    } else {
      action = "updated";
      await Provider.of<DatabaseModel>(context, listen: false).updateChallan(
        challan: widget.challan!,
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        deliveredBy: _deliveredBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
        received: _received,
        digitallySigned: _digitallySigned,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    context.showSnackBar(message: "Challan $action");
    Navigator.of(context).pop();
  }

  Card productCard(int index) {
    String subtitle =
        "${_products[index].additionalDescription}\n${_products[index].quantity} ${_products[index].quantityUnit}"
            .trim();
    return Card(
      elevation: 12,
      child: ListTile(
        title: Text(_products[index].description),
        subtitle: Text(
          subtitle,
        ),
        isThreeLine: subtitle.contains("\n"),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
          onPressed: _cancelled
              ? null
              : () {
                  setState(() {
                    _products.removeAt(index);
                  });
                },
        ),
        onTap: _cancelled ? null : () => onEditProduct(index),
      ),
    );
  }

  void onBuyerSelected(Buyer buyer) {
    setState(() {
      _buyer = buyer;
    });
    Navigator.of(context).pop();
  }

  void onAddProduct() async {
    // null represents backed out
    Product? result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ProductPage(),
    ));

    if (result != null) {
      setState(() {
        _products.add(result);
      });
    }
  }

  void onEditProduct(int index) async {
    // null represents backed out
    Product? result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProductPage(product: _products[index]),
    ));

    if (result != null) {
      setState(() {
        _products[index] = result;
      });
    }
  }
}
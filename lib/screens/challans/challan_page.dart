import 'dart:io';
import 'package:crs_manager/providers/buyer_select.dart';
import 'package:crs_manager/screens/challans/photo_page.dart';
import 'package:crs_manager/screens/challans/product_widget.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

import '../../models/buyer.dart';
import '../../providers/database.dart';
import '../../models/challan.dart';
import '../../providers/drive.dart';
import '../../utils/exceptions.dart';
import '../../utils/extensions.dart';
import '../../utils/widgets.dart';
import '../buyers/choose_buyer.dart';
import '../loading.dart';

import 'get_pdf.dart';

final formatter = DateFormat("dd-MMMM-y");

class ChallanPage extends StatefulWidget {
  const ChallanPage({super.key, this.challan, this.copyFromChallan});

  final Challan? challan;
  final Challan? copyFromChallan;

  @override
  State<ChallanPage> createState() => ChallanPageState();
}

class ChallanPageState extends State<ChallanPage> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? nextChallanInfo;
  bool _isOptionsExpanded = false;

  Buyer? _buyer;
  List<Product> _products = [];
  int _productsValue = 0;
  int? _billNumber;
  String _deliveredBy = "";
  String _vehicleNumber = "None";
  String _notes = "";
  bool _received = false;
  bool _cancelled = false;
  bool _digitallySigned = false;
  String _photoId = "";

  DateTime _createdAt = DateTime.now();

  bool get _isEditing => widget.challan != null;

  @override
  void initState() {
    if (widget.challan != null && widget.copyFromChallan != null) {
      throw Exception("both can't be provided");
    }

    var challan = widget.challan ?? widget.copyFromChallan;
    if (challan != null) {
      _buyer = challan.buyer;
      _products = List.from(challan.products);
      _productsValue = challan.productsValue;
      _deliveredBy = challan.deliveredBy;
      _vehicleNumber = challan.vehicleNumber;
      _notes = challan.notes;
      _received = challan.received;
      _digitallySigned = challan.digitallySigned;

      if (widget.challan != null) {
        // Only if editing challan, not if copying
        _billNumber = widget.challan!.billNumber;
        _cancelled = widget.challan!.cancelled;
        _photoId = widget.challan!.photoId;
        _createdAt = widget.challan!.createdAt;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: Text(_isEditing ? "Edit Challan" : "New Challan"),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.picture_as_pdf),
            itemBuilder: (context) => List.generate(
              3,
              (index) => PopupMenuItem(
                value: index + 1,
                child: Text("${index + 1} Page"),
              ),
            )..addAll(
                [
                  const PopupMenuItem<int>(
                    value: 0,
                    child: Text("Unticked"),
                  )
                ],
              ),
            onSelected: (value) => viewPdf(value),
          ),
          if (_isEditing)
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
      floatingActionButton: !_cancelled && changesMade()
          ? FloatingActionButton(
              onPressed: saveChanges,
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  Future<bool> _onWillPop() async {
    if (changesMade()) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Discard changes?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("Yes"),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  Widget actualPage() {
    var bodyTextTheme = Theme.of(context).textTheme.titleLarge;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Padding(
        padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_cancelled)
                  Card(
                    child: ListTile(
                      tileColor: Theme.of(context).colorScheme.errorContainer,
                      title: const Center(child: Text("Cancelled")),
                    ),
                  ),
                SpacedRow(
                  widget1: Text("Challan Number", style: bodyTextTheme),
                  widget2: Text(
                      "${nextChallanInfo?["number"] ?? widget.challan!.number} (${nextChallanInfo?["session"] ?? widget.challan!.session})",
                      style: bodyTextTheme),
                ),
                SizedBox(height: 2.h),
                Card(
                  elevation: 12,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text("Date"),
                    subtitle: Text(formatterDate.format(_createdAt)),
                    onTap: null,
                    // (_cancelled)
                    //     ? null
                    //     : () async {
                    //         var now = DateTime.now();
                    //         final date = await showDatePicker(
                    //           context: context,
                    //           initialDate: _createdAt,
                    //           firstDate: DateTime(2020, 1, 1),
                    //           lastDate: now.add(
                    //             const Duration(days: 31),
                    //           ),
                    //         );

                    //         if (date == null || !mounted) return;
                    //         setState(() {
                    //           _createdAt = date.copyWith(
                    //             hour: now.hour,
                    //             minute: now.minute,
                    //             second: now.second,
                    //             millisecond: now.millisecond,
                    //             microsecond: now.microsecond,
                    //           );
                    //         });
                    //       },
                    minLeadingWidth: 0,
                  ),
                ),
                SizedBox(height: 2.h),
                Card(
                  elevation: 12,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(_buyer == null
                        ? "Click to choose a buyer"
                        : _buyer!.name),
                    subtitle: Text(_buyer == null
                        ? "Click to choose a buyer"
                        : _buyer!.address),
                    onTap: _cancelled
                        ? null
                        : () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                create: (context) => BuyerSelectionProvider(
                                    onBuyerSelected: onBuyerSelected),
                                builder: (context, child) =>
                                    const ChooseBuyer(),
                              ),
                            ));
                          },
                    minLeadingWidth: 0,
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                // Products Card
                ProductWidget(
                  products: _products,
                  viewOnly: _cancelled,
                  onUpdate: () => setState(() {}),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  enabled: !_cancelled,
                  decoration: const InputDecoration(labelText: "Delivered By"),
                  initialValue: _deliveredBy,
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
                  initialValue: _vehicleNumber,
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

                ExpansionPanelList(
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isOptionsExpanded = !_isOptionsExpanded;
                    });
                  },
                  elevation: 0,
                  children: [
                    ExpansionPanel(
                        canTapOnHeader: true,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        isExpanded: _isOptionsExpanded,
                        headerBuilder: (context, isExpanded) => Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 2.h, horizontal: 2.w),
                              child: Text(
                                "Other Options",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                        body: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: [
                            SizedBox(height: 2.h),
                            TextFormField(
                              enabled: !_cancelled,
                              decoration: const InputDecoration(
                                  labelText: "Products Value"),
                              initialValue: _productsValue.toString(),
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
                              onChanged: (value) {
                                setState(() {
                                  _productsValue =
                                      int.tryParse(value) ?? _productsValue;
                                });
                              },
                              onSaved: (newValue) =>
                                  _productsValue = int.parse(newValue!),
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              enabled: !_cancelled,
                              decoration:
                                  const InputDecoration(labelText: "Notes"),
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
                            TextFormField(
                              enabled: !_cancelled,
                              decoration: const InputDecoration(
                                  labelText: "Bill Number"),
                              initialValue:
                                  widget.challan?.billNumber?.toString() ?? "",
                              validator: (value) {
                                if (value == null) {
                                  return "Field cannot be empty";
                                }
                                if (value.isEmpty) {
                                  return null;
                                }

                                if (int.tryParse(value) == null) {
                                  return "Invalid value";
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _billNumber =
                                      int.tryParse(value) ?? _billNumber;
                                });
                              },
                              onSaved: (newValue) => _billNumber =
                                  newValue!.isEmpty
                                      ? null
                                      : int.parse(newValue),
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
                              secondary:
                                  const Icon(cup.CupertinoIcons.signature),
                            ),
                            if (widget.challan != null) ...[
                              SizedBox(height: 2.h),
                              ListTile(
                                leading: const Icon(Icons.photo),
                                title: Text(_photoId.isEmpty
                                    ? "Add photo"
                                    : "View photo"),
                                onTap: viewPhoto,
                              ),
                              SizedBox(height: 2.h),
                            ],
                          ],
                        ))
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool changesMade() {
    // If new challan
    if (widget.challan == null) {
      if (_buyer != null) {
        return true;
      }
      if (_products.isNotEmpty) {
        return true;
      }
      if (_productsValue != 0) {
        return true;
      }
      if (_billNumber != null) {
        return true;
      }
      if (_deliveredBy.isNotEmpty) {
        return true;
      }
      if (_vehicleNumber != "None") {
        return true;
      }
      if (_notes.isNotEmpty) {
        return true;
      }
      if (_received) {
        return true;
      }
      if (_digitallySigned) {
        return true;
      }

      if (DateTime(_createdAt.year, _createdAt.month, _createdAt.day) !=
          DateTime.now().copyWith(
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          )) {
        return true;
      }

      return false;
    }

    var compareWith = widget.copyFromChallan ?? widget.challan!;

    if (!mapEquals(_buyer!.toMap(), compareWith.buyer.toMap())) {
      return true;
    }
    if (!const DeepCollectionEquality().equals(
      _products.map((e) => e.toMap()),
      compareWith.products.map((e) => e.toMap()),
    )) {
      return true;
    }

    if (_productsValue != compareWith.productsValue) {
      return true;
    }

    if (_billNumber != compareWith.billNumber) {
      return true;
    }

    if (_deliveredBy != compareWith.deliveredBy) {
      return true;
    }
    if (_vehicleNumber != compareWith.vehicleNumber) {
      return true;
    }
    if (_notes != compareWith.notes) {
      return true;
    }
    if (_received != compareWith.received) {
      return true;
    }
    if (_digitallySigned != compareWith.digitallySigned) {
      return true;
    }
    if (_cancelled != compareWith.cancelled) {
      return true;
    }

    if (DateTime(_createdAt.year, _createdAt.month, _createdAt.day) !=
        compareWith.createdAt.copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        )) {
      return true;
    }

    return false;
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
        billNumber: _billNumber,
        deliveredBy: _deliveredBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
        received: _received,
        digitallySigned: _digitallySigned,
        cancelled: _cancelled,
        photoId: widget.challan?.photoId ?? "",
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
    var id = widget.challan?.id;
    var db = Provider.of<DatabaseModel>(context, listen: false);

    if (widget.challan == null) {
      action = "created";
      var res = await Provider.of<DatabaseModel>(context, listen: false)
          .createChallan(
        number: nextChallanInfo!["number"],
        session: nextChallanInfo!["session"],
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        deliveredBy: _deliveredBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
        received: _received,
        digitallySigned: _digitallySigned,
        createdAt: _createdAt,
      );
      id = res.id;
    } else {
      action = "updated";
      await Provider.of<DatabaseModel>(context, listen: false).updateChallan(
        challan: widget.challan!,
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        billNumber: _billNumber,
        deliveredBy: _deliveredBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
        received: _received,
        digitallySigned: _digitallySigned,
        photoId: _photoId,
        createdAt: _createdAt,
      );

      // Firstly, update location of all old assets to office
      var oldAssets = widget.challan!.products
          .map((p) => p.assets)
          .expand((element) => element)
          .toList();
      if (oldAssets.isNotEmpty) {
        await db.updateAsset(
          assets: oldAssets,
          location: "Office",
          challanId: id,
          challanType: ChallanType.outward.index,
        );
        await db.deleteHistory(oldAssets, id!, ChallanType.outward.index);
      }
    }
    if (!mounted) return;

    // Update location of assets

    var assets =
        _products.map((p) => p.assets).expand((element) => element).toList();
    if (assets.isNotEmpty) {
      await db.updateAsset(
        assets: assets,
        location: _buyer!.name,
        challanId: id,
        challanType: ChallanType.outward.index,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    context.showSnackBar(message: "Challan $action");
    Navigator.of(context).pop();
  }

  void onBuyerSelected(Buyer buyer) {
    setState(() {
      _buyer = buyer;
    });
    Navigator.of(context).pop();
  }

  void viewPhoto() async {
    var driveHandler = Provider.of<DriveHandler>(context, listen: false);
    if (!driveHandler.inited) {
      Navigator.of(context).push(opaquePage(const LoadingPage()));
      await driveHandler.init();
      if (!mounted) return;
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    var result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PhotoPage(
        challan: widget.challan!,
      ),
    ));

    if (result == null) {
      return;
    }

    setState(() {
      _photoId = result;
    });
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

    if (!mounted || !secondResult) return;

    // Ask if they want to create an inward challan
    var createInwardChallan = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text("Create Inward Challan?"),
          content: const Text(
              "Do you want to create an inward challan for the assets in this challan?"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text("Don't do anything")),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("No")),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("Yes")),
          ]),
    );

    if (!mounted) return;

    var db = context.read<DatabaseModel>();

    var assets =
        _products.map((p) => p.assets).expand((element) => element).toList();

    if (createInwardChallan == true) {
      var newInwardChallanInfo = await db.getNextInwardChallanInfo();

      // Create inward challan
      var inwardChallan = await db.createInwardChallan(
        number: newInwardChallanInfo["number"],
        session: newInwardChallanInfo["session"],
        createdAt: DateTime.now(),
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        receivedBy: "",
        vehicleNumber: "",
        notes: "",
      );

      // Return assets to office

      if (assets.isNotEmpty) {
        await db.updateAsset(
          assets: assets,
          location: "Office",
          challanId: inwardChallan.id,
          challanType: ChallanType.inward.index,
        );
      }
    } else if (createInwardChallan == false) {
      // Not creating inward challan, just unlink assets

      // Return assets to office and delete history
      if (assets.isNotEmpty) {
        await db.updateAsset(
          assets: assets,
          location: "Office",
          challanId: null,
          challanType: null,
          reflectInHistory: false,
        );
        await db.deleteHistory(
            assets, widget.challan!.id, ChallanType.outward.index);
      }
    } else {
      // Don't do anything
    }

    if (!mounted) return;

    await Provider.of<DatabaseModel>(context, listen: false)
        .updateChallan(challan: widget.challan!, cancelled: true);

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

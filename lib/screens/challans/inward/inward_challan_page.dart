import 'package:crs_manager/models/inward_challan.dart';
import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/challans/product_widget.dart';
import 'package:crs_manager/screens/loading.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:crs_manager/utils/extensions.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../models/buyer.dart';
import '../../../models/challan.dart';
import '../../../providers/buyer_select.dart';
import '../../buyers/choose_buyer.dart';
import 'package:collection/collection.dart';

class InwardChallanPage extends StatefulWidget {
  const InwardChallanPage({super.key, this.inwardChallan});

  final InwardChallan? inwardChallan;

  @override
  State<InwardChallanPage> createState() => _InwardChallanPageState();
}

class _InwardChallanPageState extends State<InwardChallanPage> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? nextInwardChallanInfo;

  int _number = -1;
  String _session = "";
  DateTime _createdAt = DateTime.now().copyWith(
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
    microsecond: 0,
  );
  Buyer? _buyer;
  List<Product> _products = [];
  int _productsValue = 0;
  String _notes = "";
  String _receivedBy = "";
  String _vehicleNumber = "None";
  bool _cancelled = false;

  bool get _isEditing => widget.inwardChallan != null;

  @override
  void initState() {
    super.initState();
    if (widget.inwardChallan != null) {
      _number = widget.inwardChallan!.number;
      _session = widget.inwardChallan!.session;
      _createdAt = widget.inwardChallan!.createdAt;
      _buyer = widget.inwardChallan!.buyer;
      _products = List<Product>.from(widget.inwardChallan!.products);
      _productsValue = widget.inwardChallan!.productsValue;
      _notes = widget.inwardChallan!.notes;
      _receivedBy = widget.inwardChallan!.receivedBy;
      _vehicleNumber = widget.inwardChallan!.vehicleNumber;
      _cancelled = widget.inwardChallan!.cancelled;
    }

    var endOfFiscalYear = DateTime(_createdAt.year, 3, 31, 23, 59, 59);
    _session = _createdAt.isAfter(endOfFiscalYear)
        ? "${_createdAt.year}-${_createdAt.year + 1}"
        : "${_createdAt.year - 1}-${_createdAt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(builder: (context, value, child) {
      return widget.inwardChallan == null && nextInwardChallanInfo == null
          ? FutureBuilder(
              future: value.getNextInwardChallanInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  nextInwardChallanInfo = snapshot.data as Map<String, dynamic>;
                  _number = nextInwardChallanInfo?["number"];
                  _session = nextInwardChallanInfo?["session"];
                  return inwardChallanPage();
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            )
          : inwardChallanPage();
    });
  }

  Widget inwardChallanPage() {
    return Scaffold(
      appBar: TransparentAppBar(
        title: Text(
          widget.inwardChallan == null
              ? "New Inward Challan"
              : "Edit Inward Challan",
        ),
      ),
      body: WillPopScope(
        onWillPop: onWillPop,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(height: 1.h),
                TextFormField(
                  initialValue: _number != -1
                      ? _number.toString()
                      : nextInwardChallanInfo?["number"].toString(),
                  decoration: const InputDecoration(
                    labelText: "Challan Number",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null) {
                      return "Please enter a valid number";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _number = int.tryParse(value) ?? _number;
                  }),
                  onSaved: (value) {
                    _number = int.parse(value!);
                  },
                ),
                SizedBox(height: 1.h),
                SpacedRow(
                  widget1: Text("Session",
                      style: Theme.of(context).textTheme.headlineMedium),
                  widget2: Text(_session,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                SizedBox(height: 1.h),
                Card(
                  elevation: 12,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text("Date"),
                    subtitle: Text(formatterDate.format(_createdAt)),
                    onTap: (_cancelled || _isEditing)
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _createdAt,
                              firstDate: DateTime(2020, 1, 1),
                              lastDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                            );

                            if (date == null || !mounted) return;

                            setState(() {
                              _createdAt = date;
                              var endOfFiscalYear =
                                  DateTime(_createdAt.year, 3, 31, 23, 59, 59);
                              _session = _createdAt.isAfter(endOfFiscalYear)
                                  ? "${_createdAt.year}-${_createdAt.year + 1}"
                                  : "${_createdAt.year - 1}-${_createdAt.year}";
                            });
                          },
                    minLeadingWidth: 0,
                  ),
                ),
                SizedBox(height: 1.h),
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
                SizedBox(height: 1.h),
                ProductWidget(
                  products: _products,
                  viewOnly: _cancelled,
                  onUpdate: () => setState(() {}),
                  outwards: false,
                  canUpdate: () {
                    if (_buyer == null) {
                      context.showErrorSnackBar(
                          message: "Please choose a buyer first");
                    }
                    return _buyer != null;
                  },
                  comingFrom: _buyer?.name ?? "",
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  initialValue: _receivedBy,
                  decoration: const InputDecoration(
                    labelText: "Received By",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a valid name";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _receivedBy = value;
                  }),
                  onSaved: (value) {
                    _receivedBy = value!;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  initialValue: _vehicleNumber,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Number",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a valid vehicle number";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _vehicleNumber = value;
                  }),
                  onSaved: (value) {
                    _vehicleNumber = value!;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(
                    labelText: "Notes",
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  onChanged: (value) => setState(() {
                    _notes = value;
                  }),
                  onSaved: (value) {
                    _notes = value!;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  initialValue: _productsValue.toString(),
                  decoration: const InputDecoration(
                    labelText: "Products Value",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null) {
                      return "Please enter a valid number";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _productsValue = int.tryParse(value) ?? _productsValue;
                  }),
                  onSaved: (value) {
                    _productsValue = int.parse(value!);
                  },
                ),
                SizedBox(height: 5.h),
              ]),
            ),
          ),
        ),
      ),
      floatingActionButton: changesMade()
          ? FloatingActionButton(
              onPressed: savePressed,
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  void onBuyerSelected(Buyer buyer) {
    setState(() {
      _buyer = buyer;
    });
    Navigator.of(context).pop();
  }

  bool changesMade() {
    // If new challan
    if (widget.inwardChallan == null) {
      if (_number != (nextInwardChallanInfo?["number"] ?? -1)) {
        return true;
      }

      if (_createdAt !=
          DateTime.now().copyWith(
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          )) {
        return true;
      }

      if (_buyer != null) {
        return true;
      }

      if (_products.isNotEmpty) {
        return true;
      }

      if (_receivedBy.isNotEmpty) {
        return true;
      }

      if (_vehicleNumber != "None") {
        return true;
      }

      if (_notes.isNotEmpty) {
        return true;
      }

      if (_productsValue != 0) {
        return true;
      }
    }

    // If editing challan
    else {
      if (_number != widget.inwardChallan?.number) {
        return true;
      }

      if (_createdAt != widget.inwardChallan?.createdAt) {
        return true;
      }

      if (_buyer != widget.inwardChallan?.buyer) {
        return true;
      }

      if (!const DeepCollectionEquality().equals(
        _products.map((e) => e.toMap()),
        widget.inwardChallan?.products.map((e) => e.toMap()),
      )) {
        return true;
      }

      if (_receivedBy != widget.inwardChallan?.receivedBy) {
        return true;
      }

      if (_vehicleNumber != widget.inwardChallan?.vehicleNumber) {
        return true;
      }

      if (_notes != widget.inwardChallan?.notes) {
        return true;
      }

      if (_productsValue != widget.inwardChallan?.productsValue) {
        return true;
      }
    }

    return false;
  }

  Future<bool> onWillPop() async {
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

  Future<void> savePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    if (_buyer == null) {
      context.showErrorSnackBar(message: "Please choose a buyer");
      return;
    }

    if (_products.isEmpty) {
      context.showErrorSnackBar(message: "Please add at least one product");
      return;
    }

    Navigator.of(context).push(opaquePage(const LoadingPage()));
    String action = "";
    var id = widget.inwardChallan?.id;
    var db = Provider.of<DatabaseModel>(context, listen: false);

    if (widget.inwardChallan == null) {
      action = "created";
      var res = await Provider.of<DatabaseModel>(context, listen: false)
          .createInwardChallan(
        number: _number,
        session: _session,
        createdAt: _createdAt,
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        receivedBy: _receivedBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
      );
      id = res.id;
    } else {
      action = "updated";
      await Provider.of<DatabaseModel>(context, listen: false)
          .updateInwardChallan(
        inwardChallan: widget.inwardChallan!,
        number: _number,
        session: _session,
        createdAt: _createdAt,
        buyer: _buyer!,
        products: _products,
        productsValue: _productsValue,
        receivedBy: _receivedBy,
        vehicleNumber: _vehicleNumber,
        notes: _notes,
      );

      // Firstly, update location of all old assets to buyer's location
      var oldAssets = widget.inwardChallan!.products
          .map((p) => p.assets)
          .expand((element) => element)
          .toList();

      if (oldAssets.isNotEmpty) {
        await db.updateAsset(
          assets: oldAssets,
          location: widget.inwardChallan!.buyer.name,
          challanId: id,
          challanType: ChallanType.inward.index,
        );
        await db.deleteHistory(oldAssets, id!, ChallanType.inward.index);
      }
    }

    if (!mounted) return;

    // Update location of assets
    var assets =
        _products.map((p) => p.assets).expand((element) => element).toList();

    if (assets.isNotEmpty) {
      await db.updateAsset(
        assets: assets,
        location: "Office",
        challanId: id,
        challanType: ChallanType.inward.index,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    context.showSnackBar(message: "Inward Challan $action");
    Navigator.of(context).pop();
  }
}

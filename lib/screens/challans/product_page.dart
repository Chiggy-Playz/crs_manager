import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/challan.dart';
import '../loading.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, this.product});

  final Product? product;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String _description = "";
  int _quantity = 0;
  String _serial = "";
  String _additionalDescription = "";

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    if (widget.product != null) {
      _description = widget.product!.description;
      _quantity = widget.product!.quantity;
      _serial = widget.product!.serial;
      _additionalDescription = widget.product!.additionalDescription;
    }
    super.initState();
  }

  // Detect back button press, and if changes made, ask for confirmation
  Future<bool> _onWillPop() async {
    if (changesMade() && [_description].any((element) => element.isNotEmpty)) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Discard changes?"),
              content:
                  const Text("Are you sure you want to discard the changes?"),
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
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: TransparentAppBar(
          title: Text(widget.product == null ? "New Product" : "Edit Product"),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(5.w),
            children: [
              TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(
                    labelText: "Description",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a description";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _description = value;
                    });
                  },
                  onSaved: (value) => _description = value!),
              SizedBox(height: 2.h),
              TextFormField(
                  initialValue: _quantity != 0 ? _quantity.toString() : "",
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a quantity";
                    }
                    if (int.tryParse(value) == null) {
                      return "Please enter a valid quantity";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _quantity = int.tryParse(value) ?? _quantity;
                    });
                  },
                  onSaved: (value) => _quantity = int.parse(value!)),
              SizedBox(height: 2.h),
              TextFormField(
                  initialValue: _serial,
                  decoration: const InputDecoration(
                    labelText: "Serial",
                  ),
                  validator: (value) {
                    if (value == null) {
                      return "Please enter a serial";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _serial = value;
                    });
                  },
                  onSaved: (value) => _serial = value!),
              SizedBox(height: 2.h),
              TextFormField(
                  initialValue: _additionalDescription,
                  decoration: const InputDecoration(
                    labelText: "Additional Description",
                  ),
                  validator: (value) {
                    if (value == null) {
                      return "Please enter a description";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _additionalDescription = value;
                    });
                  },
                  onSaved: (value) => _additionalDescription = value!),
              SizedBox(height: 5.h),
              Center(
                  child: SizedBox(
                width: 46.w,
                height: 8.h,
                child: ElevatedButton.icon(
                  onPressed: changesMade() ? savePressed : null,
                  label: const Text("Save", style: TextStyle(fontSize: 32)),
                  icon: const Icon(Icons.save),
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }

  bool changesMade() {
    if (widget.product == null) {
      return true;
    }

    if (_description != widget.product!.description) {
      return true;
    }

    if (_quantity != widget.product!.quantity) {
      return true;
    }

    if (_serial != widget.product!.serial) {
      return true;
    }

    if (_additionalDescription != widget.product!.additionalDescription) {
      return true;
    }

    return false;
  }

  void savePressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    Navigator.of(context).pop(Product(
      description: _description,
      quantity: _quantity,
      serial: _serial,
      additionalDescription: _additionalDescription,
    ));
  }
}

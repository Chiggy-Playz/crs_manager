import 'package:crs_manager/providers/asset_select.dart';
import 'package:crs_manager/screens/assets/choose_asset.dart';
import 'package:crs_manager/utils/extensions.dart';
import 'package:crs_manager/utils/template_string.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/asset.dart';
import '../../models/challan.dart';
import '../../utils/classes.dart';
import '../../utils/widgets.dart';

// Overwrite is default, linkOnly doesnt overwrite, replace is for replacing current assets
enum AssetImportType { overwrite, linkOnly, replace }

class ProductPage extends StatefulWidget {
  const ProductPage(
      {super.key, this.product, this.outwards = true, this.comingFrom});

  final Product? product;
  final bool outwards;
  final String? comingFrom;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String _description = "";
  int _quantity = 0;
  String _quantityUnit = "";
  String _serial = "";
  String _additionalDescription = "";

  List<Asset>? assets;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _quantityUnitController = TextEditingController();
  final _serialController = TextEditingController();
  final _additionalDescriptionController = TextEditingController();

  @override
  void initState() {
    if (widget.product != null) {
      _description = widget.product!.description;
      _quantity = widget.product!.quantity;
      _quantityUnit = widget.product!.quantityUnit;
      _serial = widget.product!.serial;
      _additionalDescription = widget.product!.additionalDescription;

      if (widget.product!.assets.isNotEmpty) {
        assets = List<Asset>.from(widget.product!.assets);
      }

      _descriptionController.text = _description;
      _quantityController.text = _quantity != 0 ? _quantity.toString() : "";
      _quantityUnitController.text = _quantityUnit;
      _serialController.text = _serial;
      _additionalDescriptionController.text = _additionalDescription;
    }
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _quantityUnitController.dispose();
    _serialController.dispose();
    _additionalDescriptionController.dispose();
    super.dispose();
  }

  // Detect back button press, and if changes made, ask for confirmation
  Future<bool> _onWillPop() async {
    // Any required fields should not be empty, and should go in the list below
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
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.download),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: AssetImportType.overwrite,
                  child: Text("Overwrite (default)"),
                ),
                const PopupMenuItem(
                  value: AssetImportType.linkOnly,
                  child: Text("Don't overwrite, only link"),
                ),
                // if (assets != null && assets!.isNotEmpty)
                //   const PopupMenuItem(
                //     value: AssetImportType.replace,
                //     child: Text("Replace Assets"),
                //   ),
              ],
              onSelected: importAssetPressed,
            )
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(5.w),
            children: [
              TextFormField(
                  controller: _descriptionController,
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
              Row(
                children: [
                  SizedBox(
                    width: 55.w,
                    child: TextFormField(
                      controller: _quantityController,
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
                      onSaved: (value) => _quantity = int.parse(value!),
                    ),
                  ),
                  SizedBox(
                    width: 5.w,
                  ),
                  SizedBox(
                    width: 30.w,
                    child: TextFormField(
                      controller: _quantityUnitController,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                      ),
                      validator: (value) {
                        if (value == null) {
                          return "You shouldn't be seeing this";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _quantityUnit = value;
                        });
                      },
                      onSaved: (value) => _quantityUnit = value!,
                    ),
                  )
                ],
              ),
              SizedBox(height: 2.h),
              TextFormField(
                  controller: _serialController,
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
                  controller: _additionalDescriptionController,
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
                child: FilledButton.icon(
                  onPressed: changesMade() ? savePressed : null,
                  label: const Text("Save", style: TextStyle(fontSize: 32)),
                  icon: const Icon(Icons.save),
                ),
              )),
              if (assets != null && assets!.isNotEmpty)
                ...getLinkedAssetsWidget()
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> getLinkedAssetsWidget() {
    List<Widget> widgets = [];

    Map<MapKey, List<Asset>> groupedAssets = {};
    for (var asset in assets!) {
      var key = MapKey(asset.rawCustomFields);
      if (groupedAssets[key] == null) {
        groupedAssets[key] = [];
      }
      groupedAssets[key]!.add(asset);
    }

    widgets.addAll([
      SizedBox(height: 5.h),
      Center(
        child: Text(
          "Linked Assets",
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      SizedBox(height: 2.h),
    ]);

    widgets.add(
      ListView.builder(
        shrinkWrap: true,
        itemCount: groupedAssets.length,
        itemBuilder: (context, index) {
          var key = groupedAssets.keys.toList()[index];
          var assets = groupedAssets[key]!;

          var asset = assets.first;
          var metadata = asset.template.metadata;
          String title = asset.uuid;
          String? subtitle = "";
          if (metadata.isNotEmpty) {
            title = TemplateString(metadata.split("\n").first)
                .format(asset.rawCustomFields);

            if (metadata.contains("\n")) {
              subtitle = TemplateString(metadata.split("\n").last)
                  .format(asset.rawCustomFields);
            }
          } else {
            title += " - ${assets.last.uuid}";
            subtitle = TemplateString(metadata).format(asset.customFields);
          }

          return Card(
            elevation: 4,
            //  Only show checkbox list tile if its a single asset
            //  Since there shouldn't be merging of different types of assets in a single product
            child: ListTile(
              title: Text(title),
              subtitle: subtitle.isEmpty ? null : Text(subtitle),
              trailing: Text("${assets.length}"),
            ),
          );
        },
      ),
    );

    return widgets;
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

    if (_quantityUnit != widget.product!.quantityUnit) {
      return true;
    }

    if (_serial != widget.product!.serial) {
      return true;
    }

    if (_additionalDescription != widget.product!.additionalDescription) {
      return true;
    }

    if (assets != null && assets!.isNotEmpty) {
      if (assets!.length != widget.product!.assets.length) {
        return true;
      }

      for (var i = 0; i < assets!.length; i++) {
        if (assets![i].uuid != widget.product!.assets[i].uuid) {
          return true;
        }
      }
    }

    return false;
  }

  void savePressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    Navigator.of(context).pop(
      Product(
        description: _description.toUpperCase(),
        quantity: _quantity,
        quantityUnit: _quantityUnit.toUpperCase(),
        serial: _serial.toUpperCase(),
        additionalDescription: _additionalDescription.toUpperCase(),
        assets: assets ?? [],
      ),
    );
  }

  Future<void> importAssetPressed(AssetImportType type) async {
    assets = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChooseAsset(
          // Pop twice, first for inner list, then for outer list
          onAssetSelected: (assets) {
            Navigator.of(context).pop();
            Navigator.of(context).pop(assets);
          },
          multiple: true,
          outwards: widget.outwards,
          comingFrom: widget.comingFrom,
        ),
      ),
    );

    if (assets == null || assets!.isEmpty) {
      return;
    }

    // Ensure all assets have same template, otherwise throw error
    var templateId = assets!.first.template.id;

    if (assets!.any((element) => element.template.id != templateId)) {
      if (!mounted) return;
      context.showErrorSnackBar(message: "All assets must have same template");
      return;
    }

    // If outwards is true, that means assets are going away from office and must be in office
    // Otherwise assets are coming in office and must be in field
    // Ensure all assets' location is Office
    if (assets!.any((element) =>
        (widget.outwards && element.location != "Office") ||
        (!widget.outwards && element.location == "Office"))) {
      if (!mounted) return;
      context.showErrorSnackBar(
          message:
              "All assets must ${widget.outwards ? "" : "not"} be in Office");
      return;
    }

    if (assets!.length == 1) {
      var asset = assets!.first;
      setState(() {
        var convertedValues = asset.convertTemplateStrings();
        for (var productField in [
          "Description",
          "Quantity",
          "Quantity Unit",
          "Serial",
          "Additional Description",
        ]) {
          var convertedValue = convertedValues[productField];
          if (convertedValue == null || convertedValue.isEmpty) {
            continue;
          }

          // var templateString = TemplateString(rawAssetField);
          // var value = templateString.format(asset.toMap()["custom_fields"]);
          if (type != AssetImportType.linkOnly) {
            setFieldValue(productField, convertedValue);
          }
        }
      });
    } else {
      setState(() {
        // Loop over all assets, if field is same, set it, otherwise join it by space
        // TODO Above logic but for multiple
        for (var productField in [
          "Description",
          "Quantity",
          "Quantity Unit",
          "Serial",
          "Additional Description",
        ]) {

          var values = assets!
              .map((e) => e.convertTemplateStrings()[productField]!)
              .toList();

          // var templateString = TemplateString(rawAssetField);
          // var values = assets!
          //     .map((e) => templateString.format(e.toMap()["custom_fields"]))
          //     .toList();

          if (type != AssetImportType.linkOnly) {
            if (values.toSet().length == 1) {
              setFieldValue(productField, values.first);
            } else {
              setFieldValue(productField, values.join(" / "));
            }
          }
        }
      });
    }

    if (type != AssetImportType.linkOnly) {
      _quantity = assets!.length;
      _quantityController.text = _quantity.toString();
    }
  }

  void setFieldValue(String productField, String value) {
    switch (productField) {
      case "Description":
        _description = value;
        _descriptionController.text = _description;
        break;
      case "Quantity":
        _quantity = int.tryParse(value) ?? 0;
        _quantityController.text = _quantity.toString();
        break;
      case "Quantity Unit":
        _quantityUnit = value;
        _quantityUnitController.text = _quantityUnit;
        break;
      case "Serial":
        _serial = value;
        _serialController.text = _serial;
        break;
      case "Additional Description":
        _additionalDescription = value;
        _additionalDescriptionController.text = _additionalDescription;
        break;
    }
  }
}

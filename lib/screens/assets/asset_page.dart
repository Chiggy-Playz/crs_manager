import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/assets/optical_textformfield.dart';
import 'package:crs_manager/screens/loading.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:crs_manager/utils/exceptions.dart';
import 'package:crs_manager/utils/extensions.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/asset.dart';
import '../../models/template.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({super.key, this.asset, this.copyFromAsset});

  final Asset? asset;
  final Asset? copyFromAsset;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  Template? template;
  Map<String, FieldValue> customFields = {};

  // Asset fields
  String assetUuid = "";
  DateTime? createdAt;
  String location = "";
  int purchaseCost = 0;
  DateTime? purchaseDate;
  List<AdditionalCost> additionalCost = [];
  String purchasedFrom = "";
  String notes = "";
  int recoveredCost = 0;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      template = widget.asset!.template;
      customFields = Map.from(widget.asset!.customFields);

      // Asset Fields
      assetUuid = widget.asset!.uuid;
      createdAt = widget.asset!.createdAt;
      location = widget.asset!.location;
      purchaseCost = widget.asset!.purchaseCost;
      purchaseDate = widget.asset!.purchaseDate;
      additionalCost = List<AdditionalCost>.from(widget.asset!.additionalCost);
      purchasedFrom = widget.asset!.purchasedFrom;
      notes = widget.asset!.notes;
      recoveredCost = widget.asset!.recoveredCost;
    } else {
      if (widget.copyFromAsset != null) {
        template = widget.copyFromAsset!.template;
        customFields = Map.from(widget.copyFromAsset!.customFields);
        location = widget.copyFromAsset!.location;
        purchaseDate = widget.copyFromAsset!.purchaseDate;
        purchasedFrom = widget.copyFromAsset!.purchasedFrom;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNewAsset = widget.asset == null;
    var templates = context.watch<DatabaseModel>().templates;

    return WillPopScope(
      onWillPop: willPop,
      child: Scaffold(
        appBar: TransparentAppBar(
          title: Text(isNewAsset ? 'New Asset' : 'Edit Asset'),
          actions: [
            if (!isNewAsset)
              IconButton(
                icon: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () async {
                  var result = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Asset"),
                      content: const Text(
                          "Are you sure you want to delete this asset?"),
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

                  if (result == null || !result || !mounted) return;

                  Navigator.of(context).push(opaquePage(const LoadingPage()));

                  try {
                    await Provider.of<DatabaseModel>(context, listen: false)
                        .deleteAsset(asset: widget.asset!);
                  } catch (e) {
                    debugPrint(e.toString());
                    Navigator.of(context).pop();
                    context.showErrorSnackBar(message: e.toString());
                    return;
                  }

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  context.showSnackBar(message: "Asset Deleted");
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(children: [
                SizedBox(
                  height: 2.h,
                ),
                DropdownButtonFormField<Template>(
                  decoration: const InputDecoration(labelText: 'Template'),
                  hint: const Text("Select a template"),
                  disabledHint: template == null ? null : Text(template!.name),
                  items: List.from(templates).map(
                    (e) {
                      return DropdownMenuItem<Template>(
                        value: e,
                        child: Text(e.name),
                      );
                    },
                  ).toList(),
                  // Only enable the dropdown if we are creating a new asset
                  onChanged: isNewAsset
                      ? (Template? value) {
                          setState(() {
                            template = value;
                            if (template == null) return;
                            customFields = Map.fromEntries(
                              template!.fields.map(
                                (e) => MapEntry(
                                  e.name,
                                  FieldValue(field: e, value: null),
                                ),
                              ),
                            );
                          });
                        }
                      : null,
                  value: template,
                ),
                ...getCustomFieldWidgets(),
                ...getAssetFieldsWidgets(),
              ]),
            ),
          ),
        ),
        floatingActionButton: changesMade()
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isNewAsset) ...[
                    FloatingActionButton(
                      onPressed: () async {
                        // Ask user how many, validating an int of value at least 1, in an alert dialog box

                        int count = 1;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Create Multiple Assets"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                    "How many assets would you like to create?"),
                                SizedBox(height: 2.h),
                                TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                      labelText: "Number of Assets"),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a number';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    if (int.parse(value) <= 1) {
                                      return 'Please enter a number greater than 1';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) =>
                                      count = int.tryParse(value) ?? count,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  count = -1;
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (count <= 1) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Save"),
                              ),
                            ],
                          ),
                        );
                        if (count == -1) return;
                        await savePressed(count);
                      },
                      heroTag: "saveMany",
                      child: const Icon(Icons.queue),
                    ),
                    SizedBox(
                      height: 1.h,
                    )
                  ],
                  FloatingActionButton(
                    onPressed: savePressed,
                    child: const Icon(Icons.save),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  List<Widget> getCustomFieldWidgets() {
    var widgets = <Widget>[];

    if (template == null) {
      return widgets;
    }

    // If asset is null, just draw the widgets
    // Otherwise also fill in values

    widgets.add(SizedBox(height: 1.h));
    widgets.add(
      Center(
        child: Text("Template Fields",
            style: Theme.of(context).textTheme.headlineLarge),
      ),
    );
    widgets.add(SizedBox(height: 1.h));

    for (var field in template!.fields) {
      widgets.add(getCustomFieldWidget(field));
      widgets.add(SizedBox(height: 1.h));
    }

    return widgets;
  }

  Widget getCustomFieldWidget(Field field) {
    dynamic value = customFields[field.name]?.value;
    switch (field.type) {
      case FieldType.text:
        return OpticalTextFormField(
            labelText: field.name,
            initialValue: value ?? "",
            validator: field.required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  }
                : null,
            onChanged: (newValue) async => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: newValue!);
                }),
            onSaved: (newValue) async => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: newValue!);
                }));
      case FieldType.number:
        return OpticalTextFormField(
            labelText: field.name,
            initialValue: value?.toString() ?? "",
            keyboardType: TextInputType.number,
            validator: field.required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    if (num.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  }
                : null,
            onChanged: (newValue) async {
              var numValue = num.tryParse(newValue!);
              if (numValue == null || numValue == value) return;
              setState(() {
                customFields[field.name] =
                    FieldValue(field: field, value: numValue);
              });
            },
            onSaved: (newValue) async => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: num.parse(newValue!));
                }));
      case FieldType.datetime:
        return Card(
          elevation: 2,
          child: ListTile(
            title: Text(field.name),
            subtitle: Text(value != null
                ? formatterDateTime.format(value)
                : "Choose a date"),
            onTap: () async {
              var date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (date == null || !mounted) return;
              var time = await showTimePicker(
                  context: context, initialTime: TimeOfDay.now());

              if (time == null || !mounted) return;

              setState(() {
                customFields[field.name] = FieldValue(
                    field: field,
                    value: DateTime(date.year, date.month, date.day, time.hour,
                        time.minute));
              });
            },
          ),
        );
      case FieldType.checkbox:
        customFields[field.name] =
            FieldValue(field: field, value: value ?? false);
        return CheckboxListTile(
            title: Text(field.name),
            value: value ?? false,
            onChanged: (newValue) => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: newValue!);
                }));
    }
  }

  List<Widget> getAssetFieldsWidgets() {
    List<Widget> widgets = [];

    if (template == null) {
      return widgets;
    }

    widgets.addAll([
      Text(
        "Asset Fields",
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      SizedBox(height: 2.h),
    ]);

    if (widget.asset != null) {
      widgets.addAll([
        SpacedRow(
          widget1: Text(
            "Asset UUID",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          widget2: Text(
            assetUuid,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(height: 2.h),
        SpacedRow(
          widget1: Text(
            "Created At",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          widget2: Text(
            formatterDateTime.format(createdAt!),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(height: 2.h),
      ]);
    }

    widgets.addAll([
      TextFormField(
        decoration: const InputDecoration(labelText: "Location"),
        initialValue: location.isNotEmpty ? location : "Office",
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a location';
          }
          return null;
        },
        onChanged: (value) => setState(() => location = value),
        onSaved: (value) => setState(() => location = value!),
      ),
      SizedBox(height: 2.h),
      Card(
        elevation: 2,
        child: ListTile(
          title: const Text("Purchase Date"),
          subtitle: Text(purchaseDate != null
              ? formatterDate.format(purchaseDate!)
              : "Choose a date"),
          onTap: () async {
            var date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date == null || !mounted) return;

            setState(() {
              purchaseDate = DateTime(
                date.year,
                date.month,
                date.day,
              );
            });
          },
        ),
      ),
      SizedBox(height: 2.h),
      TextFormField(
        decoration: const InputDecoration(labelText: "Purchased From"),
        initialValue: purchasedFrom,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          return null;
        },
        onChanged: (value) => setState(() => purchasedFrom = value),
        onSaved: (value) => setState(() => purchasedFrom = value!),
      ),
      SizedBox(height: 2.h),
      TextFormField(
        decoration: const InputDecoration(labelText: "Purchase Cost"),
        initialValue: purchaseCost.toString(),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a purchase cost';
          }
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
        onChanged: (value) {
          var numValue = int.tryParse(value);
          if (numValue == null || numValue == purchaseCost) return;
          setState(() => purchaseCost = numValue);
        },
        onSaved: (value) => setState(() => purchaseCost = int.parse(value!)),
      ),
      SizedBox(height: 2.h),
      TextFormField(
        decoration: const InputDecoration(labelText: "Recovered Cost"),
        initialValue: recoveredCost.toString(),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a recovered cost';
          }
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
        onChanged: (value) {
          var numValue = int.tryParse(value);
          if (numValue == null || numValue == recoveredCost) return;
          setState(() => recoveredCost = numValue);
        },
        onSaved: (value) => setState(() => recoveredCost = int.parse(value!)),
      ),
      SizedBox(height: 2.h),
      AdditionalCostsWidget(
          intialValue: additionalCost,
          onChange: () => setState(
                () {},
              )),
      SizedBox(height: 2.h),
      TextFormField(
        decoration: const InputDecoration(labelText: "Notes"),
        initialValue: notes,
        onChanged: (value) => setState(() => notes = value),
        onSaved: (value) => setState(() => notes = value!),
      ),
      SizedBox(height: 2.h),
    ]);

    return widgets;
  }

  bool changesMade() {
    if (widget.asset == null) {
      if (location.isNotEmpty ||
          purchaseCost != 0 ||
          purchaseDate != null ||
          additionalCost.isNotEmpty ||
          recoveredCost != 0 ||
          purchasedFrom.isNotEmpty ||
          notes.isNotEmpty ||
          template != null) {
        return true;
      }
      return false;
    }

    if (location != widget.asset!.location ||
        purchaseCost != widget.asset!.purchaseCost ||
        purchaseDate != widget.asset!.purchaseDate ||
        recoveredCost != widget.asset!.recoveredCost ||
        purchasedFrom != widget.asset!.purchasedFrom ||
        notes != widget.asset!.notes ||
        template != widget.asset!.template) {
      return true;
    }

    if (customFields.length != widget.asset!.customFields.length) {
      return true;
    }

    for (var field in customFields.keys) {
      if (widget.asset!.customFields[field]!.value !=
          customFields[field]!.value) {
        return true;
      }
    }

    if (additionalCost.length != widget.asset!.additionalCost.length) {
      return true;
    }

    for (var cost in additionalCost) {
      // Check if amount or reason was changed by finding cost in widget.asset!.additionalCost

      var oldCost = widget.asset!.additionalCost
          .where(
            (element) =>
                element.reason == cost.reason && element.amount == cost.amount,
          )
          .toList();

      if (oldCost.isEmpty) {
        return true;
      }
    }

    return false;
  }

  Future<void> savePressed([int count = 1]) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    // Make sure purchase date is set
    if (purchaseDate == null) {
      context.showErrorSnackBar(message: "Please select a purchase date");
      return;
    }

    try {
      // Check if all custom fields are set properly, respecting the required flag
      customFields.forEach((fieldName, fieldValue) {
        if (fieldValue.field.required && (fieldValue.value == null)) {
          throw UnfilledFieldsError();
        }
      });
    } on UnfilledFieldsError catch (_) {
      context.showErrorSnackBar(message: "Please fill in all required fields");
      return;
    }
    Navigator.of(context).push(opaquePage(const LoadingPage()));

    try {
      // Create new asset
      if (widget.asset == null) {
        await Provider.of<DatabaseModel>(context, listen: false).createAsset(
          location: location,
          purchaseCost: purchaseCost,
          purchaseDate: purchaseDate!,
          additionalCost: additionalCost,
          purchasedFrom: purchasedFrom,
          template: template!,
          customFields: customFields,
          notes: notes,
          recoveredCost: recoveredCost,
          count: count,
        );
      } else {
        // Update existing asset

        await Provider.of<DatabaseModel>(context, listen: false).updateAsset(
          assets: [widget.asset!],
          location: location == widget.asset!.location ? null : location,
          purchaseCost:
              purchaseCost == widget.asset!.purchaseCost ? null : purchaseCost,
          purchaseDate:
              purchaseDate == widget.asset!.purchaseDate ? null : purchaseDate,
          additionalCost: additionalCost,
          purchasedFrom: purchasedFrom == widget.asset!.purchasedFrom
              ? null
              : purchasedFrom,
          notes: notes == widget.asset!.notes ? null : notes,
          recoveredCost: recoveredCost == widget.asset!.recoveredCost
              ? null
              : recoveredCost,
          customFields: Map.from(customFields),
        );
      }
    } catch (e, stacktrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stacktrace);
      Navigator.of(context).pop();
      context.showErrorSnackBar(message: e.toString());
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    context.showSnackBar(message: "Asset Saved");
    Navigator.of(context).pop();
  }

  Future<bool> willPop() async {
    // If no changes have been made, just pop
    if (!changesMade()) {
      return true;
    }

    // If changes have been made, tell the user to save first
    // show a dialog asking if they want to save

    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("You have unsaved changes"),
        content: const Text("Are you sure you want to discard your changes?"),
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

    if (result == null) {
      return false;
    }

    return result;
  }
}

class AdditionalCostsWidget extends StatefulWidget {
  const AdditionalCostsWidget(
      {super.key, required this.intialValue, required this.onChange});

  final List<AdditionalCost> intialValue;
  final Function onChange;

  @override
  State<AdditionalCostsWidget> createState() => _AdditionalCostsWidgetState();
}

class _AdditionalCostsWidgetState extends State<AdditionalCostsWidget> {
  late List<AdditionalCost> additionalCost;

  @override
  void initState() {
    super.initState();
    additionalCost = widget.intialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: additionalCost.isEmpty ? 25.h : 45.h,
      width: double.infinity,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            children: [
              Text(
                "Additional Costs",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              if (additionalCost.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    // + 2 for the divider and the last row showing total
                    itemCount: additionalCost.length + 2,
                    itemBuilder: (context, index) {
                      return costCard(index);
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      "None",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              FloatingActionButton.extended(
                heroTag: "addAdditionalCost",
                onPressed: onAdd,
                label: const Text("Add Cost"),
                icon: const Icon(Icons.add),
              )
            ],
          ),
        ),
      ),
    );
  }

  void onAdd() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) =>
          AdditionalCostModalWidget(additionalCost: additionalCost),
      isScrollControlled: true,
    );

    widget.onChange();
    setState(() {});
  }

  Future<void> onEdit(int index) async {
    await showModalBottomSheet(
        context: context,
        builder: (context) => AdditionalCostModalWidget(
              additionalCost: additionalCost,
              index: index,
            ),
        isScrollControlled: true);

    widget.onChange();
    setState(() {});
  }

  Widget costCard(int index) {
    if (index < additionalCost.length) {
      AdditionalCost cost = additionalCost.elementAt(index);
      return Card(
        elevation: 12,
        child: ListTile(
          title: Text(cost.reason),
          subtitle: Text(formatterDate.format(cost.when)),
          trailing: Text(
            numberFormatter.format(cost.amount),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          onTap: () => onEdit(index),
        ),
      );
    } else if (index == additionalCost.length) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: const Divider(),
      );
    } else {
      return Card(
        elevation: 12,
        child: ListTile(
          title: const Text("Total"),
          trailing: Text(
            numberFormatter.format(additionalCost
                .map(
                  (e) => e.amount,
                )
                .reduce((a, b) => a + b)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }
  }
}

class AdditionalCostModalWidget extends StatefulWidget {
  const AdditionalCostModalWidget(
      {super.key, required this.additionalCost, this.index});

  final List<AdditionalCost> additionalCost;
  final int? index;

  @override
  State<AdditionalCostModalWidget> createState() =>
      _AdditionalCostModalWidgetState();
}

class _AdditionalCostModalWidgetState extends State<AdditionalCostModalWidget> {
  String reason = "";
  int amount = 0;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      var cost = widget.additionalCost.elementAt(widget.index!);
      reason = cost.reason;
      amount = cost.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool newCost = widget.index == null;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 2.h,
        left: 4.w,
        right: 4.w,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      newCost ? "New Cost" : "Edit Cost",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  if (!newCost)
                    IconButton(
                        onPressed: () {
                          widget.additionalCost.remove(
                              widget.additionalCost.elementAt(widget.index!));
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        )),
                  SizedBox(width: 1.w),
                  FilledButton.icon(
                    onPressed: savePressed,
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                  )
                ],
              ),
              SizedBox(height: 3.h),
              TextFormField(
                decoration: const InputDecoration(
                    hintText: "Reason", label: Text("Reason")),
                initialValue: reason,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter a reason";
                  }
                  return null;
                },
                onSaved: (value) => reason = value!,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                decoration: const InputDecoration(
                    hintText: "Cost", label: Text("Cost")),
                initialValue: amount.toString(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter a cost";
                  }
                  if (int.tryParse(value) == null) {
                    return "Please enter a valid number";
                  }
                  return null;
                },
                onSaved: (value) => amount = int.parse(value!),
              ),
              SizedBox(height: 2.h)
            ],
          ),
        ),
      ),
    );
  }

  Future<void> savePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    // Mutate the additionalCosts map in the parent widget
    if (widget.index == null) {
      widget.additionalCost.add(
          AdditionalCost(amount: amount, reason: reason, when: DateTime.now()));
    } else {
      widget.additionalCost[widget.index!] =
          AdditionalCost(amount: amount, reason: reason, when: DateTime.now());
    }

    Navigator.of(context).pop();
  }
}

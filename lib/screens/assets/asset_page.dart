import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/assets/optical_textformfield.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/asset.dart';
import '../../models/template.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({super.key, this.asset});

  final Asset? asset;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  Template? template;
  Map<String, FieldValue> customFields = {};

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      template = widget.asset!.template;
      customFields = Map.from(widget.asset!.customFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNewAsset = widget.asset == null;
    var templates = context.watch<DatabaseModel>().templates;

    return Scaffold(
      appBar: TransparentAppBar(
        title: Text(isNewAsset ? 'New Asset' : 'Edit Asset'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(children: [
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
              ...getCustomFieldWidgets()
            ]),
          ),
        ),
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
            onSaved: (newValue) async => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: newValue!);
                }));
      case FieldType.number:
        return OpticalTextFormField(
            labelText: field.name,
            initialValue: value ?? "",
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
            onSaved: (newValue) async => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: newValue!);
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
        return CheckboxListTile(
            title: Text(field.name),
            value: value ?? false,
            onChanged: (newValue) => setState(() {
                  customFields[field.name] =
                      FieldValue(field: field, value: newValue!);
                }));
    }
  }
}

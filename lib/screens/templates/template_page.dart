import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:crs_manager/utils/exceptions.dart';
import 'package:crs_manager/utils/extensions.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/template.dart';
import '../loading.dart';

class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key, this.template});

  final Template? template;

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  String name = "";
  List<Field> fields = [];
  Map<String, String> productLink = {
    "Description": "",
    "Serial": "",
    "Quantity": "",
    "Quantity Unit": "",
    "Additional Description": "",
  };
  bool advancedView = false;
  String metadata = "";

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      name = widget.template!.name;
      fields = List.from(widget.template!.fields);
      productLink = Map.from(widget.template!.productLink);
      metadata = widget.template!.metadata;
    } else {
      // Add default fields
      fields.add(Field(
        name: "Description",
        type: FieldType.text,
        required: true,
        templates: {},
        defaultValue: "",
      ));
      fields.add(
        Field(
          name: "Model",
          type: FieldType.text,
          required: true,
          templates: {},
          defaultValue: "",
        ),
      );
      fields.add(Field(
        name: "Serial",
        type: FieldType.text,
        required: false,
        templates: {},
        defaultValue: "",
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: TransparentAppBar(
          title:
              Text(widget.template == null ? "New Template" : "Edit Template"),
          actions: [
            if (widget.template != null)
              IconButton(
                  onPressed: () async {
                    // Confirm delete
                    bool? delete = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Template?"),
                        content: const Text(
                            "Are you sure you want to delete this template?"),
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

                    if (delete == null || !delete || !mounted) return;

                    Navigator.of(context).push(opaquePage(const LoadingPage()));

                    try {
                      await Provider.of<DatabaseModel>(context, listen: false)
                          .deleteTemplate(widget.template!);
                    } on TemplateInUseError {
                      Navigator.pop(context);
                      context.showErrorSnackBar(message: "Template in use");
                      return;
                    } catch (e) {
                      Navigator.pop(context);
                      context.showErrorSnackBar(
                          message: "Failed to delete: $e");
                      return;
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    Navigator.pop(context);
                    context.showSnackBar(message: "Template deleted");
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  )),
            advancedView
                ? IconButton.filled(
                    onPressed: () =>
                        setState(() => advancedView = !advancedView),
                    icon: const Icon(Icons.settings))
                : IconButton(
                    onPressed: () =>
                        setState(() => advancedView = !advancedView),
                    icon: const Icon(Icons.settings),
                  )
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10.h,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: "Template Name",
                    ),
                    initialValue: name,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter a name";
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() => name = value),
                    onSaved: (value) => name = value!,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  "Fields",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(height: 1.h),
                getFieldsListWidget(),
                SizedBox(height: 1.h),
                ...getProductsLinkWidget(),
                SizedBox(height: 1.h),
                ...getMetadataWidget(),
              ],
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (changesMade()) ...[
              FloatingActionButton(
                onPressed: savePressed,
                heroTag: "Save-fab",
                child: const Icon(Icons.save),
              ),
              SizedBox(height: 1.h),
            ],
            FloatingActionButton(
              onPressed: addField,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget getFieldsListWidget() {
    var widgets = <Widget>[];

    if (fields.isEmpty) {
      return Text(
        "No fields added",
        style: Theme.of(context).textTheme.titleMedium,
      );
    }

    for (var field in fields) {
      // Icon based on type of field
      Icon icon;
      switch (field.type) {
        case FieldType.text:
          icon = const Icon(Icons.text_fields);
          break;
        case FieldType.number:
          icon = const Icon(Icons.onetwothree);
          break;
        case FieldType.datetime:
          icon = const Icon(Icons.date_range);
          break;
        case FieldType.checkbox:
          icon = const Icon(Icons.check_box);
          break;
        case FieldType.select:
          icon = const Icon(Icons.list);
          break;
      }

      widgets.add(ListTile(
        key: ValueKey(field),
        leading: icon,
        title: Text(field.name),
        subtitle: Text(
            field.type.name.capitalize + (field.required ? " (Required)" : "")),
        trailing: IconButton(
          icon: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            setState(() {
              fields.remove(field);
            });
          },
        ),
        onTap: () => editField(field),
        isThreeLine: true,
      ));
    }

    return ReorderableListView(
      shrinkWrap: true,
      children: widgets,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = fields.removeAt(oldIndex);
          fields.insert(newIndex, item);
        });
      },
    );
  }

  Future<void> addField() async {
    Field? field = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return const FieldWidget();
      },
    );

    // Not saved
    if (field == null) return;

    setState(() {
      fields.add(field);
    });
  }

  Future<void> editField(Field field) async {
    Field? newField = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return FieldWidget(field: field);
      },
    );

    // Not saved
    if (newField == null) return;

    setState(() {
      fields[fields.indexOf(field)] = newField;
    });
  }

  List<Widget> getProductsLinkWidget() {
    List<Widget> widgets = [];

    if (fields.isEmpty) {
      return widgets;
    }

    widgets.add(
      Text(
        "Product Relation",
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );

    var productFields = [
      "Description",
      "Serial",
      "Quantity",
      "Quantity Unit",
      "Additional Description",
    ];

    TextFormField getTextField(String productField) {
      return TextFormField(
        initialValue: productLink[productField],
        onChanged: (value) {
          setState(() {
            productLink[productField] = value;
          });
        },
      );
    }

    widgets.addAll(productFields.map(
      (productField) {
        return SpacedRow(
          widget1: SizedBox(
            width: 40.w,
            child: Text(
              productField,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          widget2: SizedBox(
            width: 50.w,
            child: advancedView
                ? getTextField(productField)
                : (fields
                            .map(
                              (e) => "{${e.name}}",
                            )
                            .contains(productLink[productField]) ||
                        productLink[productField] == ""
                    ? DropdownButtonFormField<String>(
                        items: fields
                            .map(
                              (field) => DropdownMenuItem(
                                value: "{${field.name}}",
                                child: Text(field.name),
                              ),
                            )
                            .toList()
                          ..add(const DropdownMenuItem(
                            value: "",
                            child: Text("Empty"),
                          )),
                        onChanged: (value) {
                          setState(() {
                            productLink[productField] = value!;
                          });
                        },
                        value: productLink[productField],
                      )
                    : getTextField(productField)),
          ),
        );
      },
    ));

    // Add some space between every widget by adding a SizedBox
    List<Widget> spacedWidgets = [];
    for (var i = 0; i < widgets.length; i++) {
      spacedWidgets.add(widgets[i]);
      if (i != widgets.length - 1) {
        spacedWidgets.add(SizedBox(height: 1.h));
      }
    }

    return spacedWidgets;
  }

  bool changesMade() {
    if (widget.template == null) {
      return name.isNotEmpty || fields.isNotEmpty;
    }

    if (name != widget.template!.name) {
      return true;
    }

    if (fields.length != widget.template!.fields.length) {
      return true;
    }

    for (var i = 0; i < fields.length; i++) {
      if (fields[i] != widget.template!.fields[i]) {
        return true;
      }
    }

    // Check if product link values changed
    for (var key in productLink.keys) {
      if (productLink[key] != widget.template!.productLink[key]) {
        return true;
      }
    }

    if (metadata != widget.template!.metadata) {
      return true;
    }

    return false;
  }

  Future<void> savePressed() async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a name"),
        ),
      );
      return;
    }

    if (fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one field"),
        ),
      );
      return;
    }

    if (metadata.isNotEmpty) {
      // Check if metadata is valid
      if (metadata.split("\n").length > 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Metadata can only have 2 lines"),
          ),
        );
        return;
      }

      if (metadata.split("\n").any((element) => element.length > 50)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Metadata lines can only have 50 characters"),
          ),
        );
        return;
      }

      metadata = metadata.trim();
    }

    Navigator.of(context).push(opaquePage(const LoadingPage()));

    String action = widget.template == null ? "create" : "update";

    try {
      if (widget.template == null) {
        await Provider.of<DatabaseModel>(context, listen: false).createTemplate(
            name: name,
            fields: fields,
            productLink: productLink,
            metadata: metadata);
      } else {
        await Provider.of<DatabaseModel>(context, listen: false).updateTemplate(
          template: widget.template!,
          name: name,
          fields: fields,
          productlink: productLink,
          metadata: metadata,
        );
      }
    } catch (e) {
      print(e);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to $action template"),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    context.showSnackBar(message: "Template $action successful");
    Navigator.pop(context);
  }

  // Detect back button press, and if changes made, ask for confirmation
  Future<bool> onWillPop() async {
    // Any required fields should not be empty, and should go in the list below
    if (changesMade()) {
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

  List<Widget> getMetadataWidget() {
    List<Widget> widgets = [];

    // if (widget.template == null) {
    //   return widgets;
    // }

    widgets.add(
      Text(
        "Metadata",
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );

    widgets.add(
      SizedBox(
        height: 1.h,
      ),
    );

    widgets.addAll([
      TextFormField(
        decoration: const InputDecoration(
          hintText: "Metadata Line 1",
          labelText: "Metadata Line 1",
        ),
        initialValue: metadata.split("\n").firstOrNull ?? "",
        onChanged: (value) {
          setState(() {
            // If \n is in metadata, replace anything before it with value
            if (metadata.contains("\n")) {
              metadata = "$value\n${metadata.split("\n").last}";
            } else {
              metadata = value;
            }
          });
        },
      ),
      SizedBox(
        height: 1.h,
      ),
      TextFormField(
        decoration: const InputDecoration(
          hintText: "Metadata Line 2",
          labelText: "Metadata Line 2",
        ),
        initialValue: metadata.split("\n").elementAtOrNull(1) ?? "",
        onChanged: (value) {
          setState(() {
            // If \n is in metadata, replace anything after it with value
            if (metadata.contains("\n")) {
              metadata = "${metadata.split("\n").first}\n$value";
            } else {
              metadata = "$metadata\n$value";
            }
          });
        },
      ),
    ]);

    return widgets;
  }
}

class FieldWidget extends StatefulWidget {
  const FieldWidget({super.key, this.field});

  final Field? field;

  @override
  State<FieldWidget> createState() => _FieldWidgetState();
}

class _FieldWidgetState extends State<FieldWidget> {
  String name = "";
  FieldType type = FieldType.text;
  // Default required is true for new fields
  bool required = true;
  Map<String, String> templates = {};
  dynamic defaultValue;

  List<String> selectOptions = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.field != null) {
      name = widget.field!.name;
      type = widget.field!.type;
      required = widget.field!.required;
      templates = widget.field!.templates;
      defaultValue = widget.field!.defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool newField = widget.field == null;
    List<Widget> templateWidgets = [];

    if (type == FieldType.checkbox) {
      templateWidgets.add(
        TextFormField(
          decoration: const InputDecoration(
            hintText: "Checked",
            labelText: "Checked",
          ),
          initialValue: templates["true"],
          onSaved: (value) => templates["true"] = value!,
        ),
      );
      templateWidgets.add(SizedBox(
        height: 1.h,
      ));
      templateWidgets.add(
        TextFormField(
          decoration: const InputDecoration(
            hintText: "Unchecked",
            labelText: "Unchecked",
          ),
          initialValue: templates["false"],
          onSaved: (value) => templates["false"] = value!,
        ),
      );
    }

    if (type == FieldType.text) {
      templateWidgets.add(
        TextFormField(
          decoration: const InputDecoration(
            hintText: "If empty",
            labelText: "If empty",
          ),
          initialValue: templates["empty"],
          onSaved: (value) => templates["empty"] = value!,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      newField ? "New Field" : "Edit Field",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
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
                    hintText: "Name", label: Text("Name")),
                initialValue: name,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  hintText: "Type",
                  label: Text("Type"),
                ),
                items: const [
                  DropdownMenuItem(
                    value: FieldType.text,
                    child: Text("Text"),
                  ),
                  DropdownMenuItem(
                    value: FieldType.number,
                    child: Text("Number"),
                  ),
                  DropdownMenuItem(
                    value: FieldType.datetime,
                    child: Text("Date Time"),
                  ),
                  DropdownMenuItem(
                    value: FieldType.checkbox,
                    child: Text("Checkbox"),
                  ),
                  DropdownMenuItem(
                    value: FieldType.select,
                    child: Text("Dropdown"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    type = value!;
                    defaultValue = null;
                  });
                },
                value: type,
              ),
              SizedBox(height: 2.h),
              SwitchListTile(
                value: required,
                onChanged: (value) {
                  setState(() {
                    required = value;
                  });
                },
                title: const Text("Required?"),
              ),
              SizedBox(
                height: 2.h,
              ),
              defaultWidget(),
              if (type == FieldType.select) ...[
                SizedBox(
                  height: 2.h,
                ),
                selectOptionsWidgets(),
                Card(
                  elevation: 20,
                  child: ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text("Add Option"),
                    onTap: () async {
                      String? option = await showDialog(
                        context: context,
                        builder: (context) {
                          return const SelectOptionDialog();
                        },
                      );

                      if (option == null || !mounted) return;

                      setState(() {
                        selectOptions.add(option);
                      });
                    },
                  ),
                ),
              ],
              SizedBox(
                height: 2.h,
              ),
              if (templateWidgets.isNotEmpty) ...[
                Text(
                  "Templates",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(
                  height: 1.h,
                ),
                ...templateWidgets,
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget defaultWidget() {
    switch (type) {
      case FieldType.text:
        return TextFormField(
          decoration: const InputDecoration(
            hintText: "Default Value",
            labelText: "Default Value",
          ),
          initialValue: defaultValue ?? "",
          onSaved: (value) => defaultValue = value!,
        );

      case FieldType.number:
        return TextFormField(
          decoration: const InputDecoration(
            hintText: "Default Value",
            labelText: "Default Value",
          ),
          initialValue: defaultValue?.toString() ?? "",
          onSaved: (value) {
            if (value == null || value.isEmpty) {
              defaultValue = null;
              return;
            }
            defaultValue = int.tryParse(value);
          },
          keyboardType: TextInputType.number,
        );

      case FieldType.datetime:
        return Card(
          elevation: 2,
          child: ListTile(
            title: const Text("Default"),
            subtitle: Text(defaultValue != null
                ? formatterDateTime.format(defaultValue)
                : "Choose a date"),
            trailing: defaultValue == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () {
                      setState(() {
                        defaultValue = null;
                      });
                    },
                  ),
            onTap: () async {
              var date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (date == null || !mounted) return;
              var time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (time == null || !mounted) return;

              setState(() {
                defaultValue = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            },
          ),
        );
      case FieldType.checkbox:
        return SwitchListTile(
          value: defaultValue ?? false,
          onChanged: (value) {
            setState(() {
              defaultValue = value;
            });
          },
          title: const Text("Default Value"),
        );

      case FieldType.select:
        return Row(
          children: [
            Expanded(
              child: DropdownMenu(
                key: ValueKey(defaultValue),
                dropdownMenuEntries:
                    selectOptions.map<DropdownMenuEntry<String>>((e) {
                  return DropdownMenuEntry<String>(
                    value: e,
                    label: e,
                  );
                }).toList(),
                label: const Text("Default Value"),
                expandedInsets: EdgeInsets.symmetric(
                    horizontal: 1.w), // no clue how this works
                onSelected: (value) {
                  if (value == null) return;
                  setState(() {
                    defaultValue = value;
                  });
                },
                initialSelection: defaultValue,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              onPressed: () {
                setState(() {
                  defaultValue = null;
                });
              },
            ),
          ],
        );
    }
  }

  Widget selectOptionsWidgets() {
    if (selectOptions.isEmpty) {
      return const Card(
          child: ListTile(
        title: Text("No Options"),
      ));
    }

    return ReorderableListView.builder(
      itemCount: selectOptions.length,
      itemBuilder: (context, index) {
        return Card(
          key: ValueKey(selectOptions[index]),
          child: ListTile(
            title: Text(selectOptions[index]),
            leading: const Icon(Icons.list),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              onPressed: () {
                setState(() {
                  selectOptions.removeAt(index);
                });
              },
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = selectOptions.removeAt(oldIndex);
          selectOptions.insert(newIndex, item);
        });
      },
      shrinkWrap: true,
    );
  }

  Future<void> savePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    if (type == FieldType.select && selectOptions.isEmpty) {
      context.showErrorSnackBar(message: "Please add at least one option");
      return;
    }

    Navigator.pop(
      context,
      Field(
        name: name,
        type: type,
        required: required,
        templates: templates,
        defaultValue: defaultValue,
        selectOptions: type == FieldType.select ? selectOptions : null,
      ),
    );
  }
}

class SelectOptionDialog extends StatefulWidget {
  const SelectOptionDialog({super.key, this.option});

  final String? option;

  @override
  State<SelectOptionDialog> createState() => _SelectOptionDialogState();
}

class _SelectOptionDialogState extends State<SelectOptionDialog> {
  String option = "";

  @override
  void initState() {
    super.initState();
    option = widget.option ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${widget.option == null ? "Add" : "Edit"} Option"),
      content: TextFormField(
        initialValue: widget.option,
        decoration: const InputDecoration(
          hintText: "Option",
          labelText: "Option",
        ),
        onChanged: (value) {
          setState(() {
            option = value;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: option == widget.option
              ? null
              : () => Navigator.pop(context, option),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

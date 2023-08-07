import 'package:crs_manager/providers/database.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      name = widget.template!.name;
      fields = List.from(widget.template!.fields);
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
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          child: Center(
            child: Column(
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
                ...getFieldsListWidget(),
                SizedBox(height: 1.h),
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
                child: const Icon(Icons.save),
                heroTag: "Save-fab",
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

  List<Widget> getFieldsListWidget() {
    var widgets = <Widget>[];

    if (fields.isEmpty) {
      return [
        Text(
          "No fields added",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ];
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
      }

      widgets.add(ListTile(
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

    return widgets;
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

    Navigator.of(context).push(opaquePage(const LoadingPage()));

    String action = widget.template == null ? "create" : "update";

    try {
      if (widget.template == null) {
        await Provider.of<DatabaseModel>(context, listen: false)
            .createTemplate(name: name, fields: fields);
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
  bool required = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.field != null) {
      name = widget.field!.name;
      type = widget.field!.type;
      required = widget.field!.required;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool newField = widget.field == null;
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
                ],
                onChanged: (value) {
                  setState(() {
                    type = value!;
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

    Navigator.pop(
      context,
      Field(
        name: name,
        type: type,
        required: required,
      ),
    );
  }
}

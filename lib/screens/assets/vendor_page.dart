import 'package:crs_manager/utils/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/vendor.dart';
import '../../providers/database.dart';
import '../../utils/extensions.dart';
import '../../utils/widgets.dart';
import '../loading.dart';

class VendorPage extends StatefulWidget {
  const VendorPage({super.key, this.vendor});

  final Vendor? vendor;

  @override
  State<VendorPage> createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> {
  final _formKey = GlobalKey<FormState>();
  final _gstController = TextEditingController();

  String _name = "";
  String _address = "";
  String _gst = "";
  String _codeNumber = "";
  String _mobileNumber = "";
  String _notes = "";

  @override
  void initState() {
    if (widget.vendor != null) {
      _name = widget.vendor!.name;
      _address = widget.vendor!.address;
      _gst = widget.vendor!.gst;
      _codeNumber = widget.vendor!.codeNumber;
      _mobileNumber = widget.vendor!.mobileNumber;
      _notes = widget.vendor!.notes;
      _gstController.text = _gst;
    }
    super.initState();
  }

  @override
  void dispose() {
    _gstController.dispose();
    super.dispose();
  }

  // Detect back button press, and if changes made, ask for confirmation
  Future<bool> _onWillPop() async {
    // Any required fields should not be empty, and should go in the list below
    if (changesMade() &&
        [_name, _address, _gst, _codeNumber, _mobileNumber]
            .any((element) => element.isNotEmpty)) {
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
    return Scaffold(
      appBar: TransparentAppBar(
        title: Text(
          widget.vendor == null ? "New Vendor" : "Edit Vendor",
        ),
        actions: [
          if (widget.vendor != null)
            IconButton(
              onPressed: deleteVendor,
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
            )
        ],
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 5.w,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Name",
                  ),
                  initialValue:
                      widget.vendor == null ? "" : widget.vendor!.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a name";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _name = value;
                  }),
                  onSaved: (newValue) => _name = newValue!,
                ),
                SizedBox(
                  height: 2.h,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Address",
                  ),
                  initialValue:
                      widget.vendor == null ? "" : widget.vendor!.address,
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter an address";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _address = value;
                  }),
                  onSaved: (newValue) => _address = newValue!,
                ),
                SizedBox(
                  height: 2.h,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: "GST",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter a GST";
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {
                          _gst = value;
                        }),
                        onSaved: (newValue) => _gst = newValue!,
                      ),
                    ),
                    SizedBox(
                      width: 2.w,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _gstController.text = "NOT AVAILABLE";
                        setState(() {
                          _gst = "NOT AVAILABLE";
                        });
                      },
                      child: const Text("N/A"),
                    ),
                  ],
                ),
                SizedBox(
                  height: 2.h,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Code Number",
                  ),
                  initialValue:
                      widget.vendor == null ? "" : widget.vendor!.codeNumber,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a code number";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _codeNumber = value;
                  }),
                  onSaved: (newValue) => _codeNumber = newValue!,
                ),
                SizedBox(
                  height: 2.h,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                  ),
                  initialValue:
                      widget.vendor == null ? "" : widget.vendor!.mobileNumber,
                  onChanged: (value) => setState(() {
                    _mobileNumber = value;
                  }),
                  onSaved: (newValue) => _mobileNumber = newValue!,
                ),
                SizedBox(
                  height: 2.h,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Notes",
                  ),
                  initialValue:
                      widget.vendor == null ? "" : widget.vendor!.notes,
                  onChanged: (value) => setState(() {
                    _notes = value;
                  }),
                  onSaved: (newValue) => _notes = newValue!,
                ),
                SizedBox(
                  height: 5.h,
                ),
                Center(
                    child: SizedBox(
                  width: 46.w,
                  height: 8.h,
                  child: FilledButton.icon(
                    onPressed: changesMade() ? savePressed : null,
                    label: const Text("Save", style: TextStyle(fontSize: 32)),
                    icon: const Icon(Icons.save),
                  ),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool changesMade() {
    if (widget.vendor == null) {
      return true;
    }

    if (_name != widget.vendor!.name) {
      return true;
    }

    if (_address != widget.vendor!.address) {
      return true;
    }

    if (_gst != widget.vendor!.gst) {
      return true;
    }

    if (_codeNumber != widget.vendor!.codeNumber) {
      return true;
    }

    if (_mobileNumber != widget.vendor!.mobileNumber) {
      return true;
    }

    if (_notes != widget.vendor!.notes) {
      return true;
    }

    return false;
  }

  void savePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    Navigator.of(context).push(opaquePage(const LoadingPage()));

    String action = "";
    try {
      // Create vendor
      if (widget.vendor == null) {
        action = "created";
        await Provider.of<DatabaseModel>(context, listen: false).createVendor(
          name: _name,
          address: _address,
          gst: _gst,
          codeNumber: _codeNumber,
          mobileNumber: _mobileNumber,
          notes: _notes,
        );
      } else {
        action = "updated";
        await Provider.of<DatabaseModel>(context, listen: false).updateVendor(
          vendor: widget.vendor!,
          name: _name,
          address: _address,
          gst: _gst,
          codeNumber: _codeNumber,
          mobileNumber: _mobileNumber,
          notes: _notes,
        );
      }
    } on VendorInUseError {
      Navigator.of(context).pop();
      context.showErrorSnackBar(message: "Vendor is in use");
      return;
    } catch (e) {
      Navigator.of(context).pop();
      context.showErrorSnackBar(message: "An error occurred");
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    context.showSnackBar(message: "Vendor $action");
    Navigator.of(context).pop();
  }

  void deleteVendor() async {
    // Prompt user to confirm deletion
    final delete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Vendor"),
        content: const Text("Are you sure you want to delete this vendor?"),
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

    if (!delete) {
      return;
    }

    // Show loading
    if (!mounted) return;
    Navigator.of(context).push(opaquePage(const LoadingPage()));

    try {
      // Delete vendor from database
      await Provider.of<DatabaseModel>(context, listen: false)
          .deleteVendor(widget.vendor!);
    } on VendorInUseError {
      Navigator.of(context).pop();
      context.showErrorSnackBar(message: "Vendor is in use");
      return;
    } catch (e) {
      Navigator.of(context).pop();
      context.showErrorSnackBar(message: "An error occurred");
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    context.showSnackBar(message: "Vendor deleted");
    Navigator.of(context).pop();
  }
}

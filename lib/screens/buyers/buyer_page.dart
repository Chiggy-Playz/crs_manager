import 'package:crs_manager/models/buyer.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/database.dart';
import '../loading.dart';
import '../../utils/extensions.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key, this.buyer});

  final Buyer? buyer;

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final _formKey = GlobalKey<FormState>();
  final _gstController = TextEditingController();

  String _name = "";
  String _address = "";
  String _gst = "";
  String _state = "";

  @override
  void initState() {
    if (widget.buyer != null) {
      _name = widget.buyer!.name;
      _address = widget.buyer!.address;
      _gst = widget.buyer!.gst;
      _state = widget.buyer!.state;
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
        [_name, _address, _gst, _state].any((element) => element.isNotEmpty)) {
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
          widget.buyer == null ? "New Buyer" : "Edit Buyer",
        ),
        actions: [
          if (widget.buyer is Buyer)
            IconButton(
              onPressed: deleteBuyer,
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
                  initialValue: widget.buyer == null ? "" : widget.buyer!.name,
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
                      widget.buyer == null ? "" : widget.buyer!.address,
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
                    labelText: "State",
                  ),
                  initialValue: widget.buyer == null ? "" : widget.buyer!.state,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a state";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {
                    _state = value;
                  }),
                  onSaved: (newValue) => _state = newValue!,
                ),
                SizedBox(
                  height: 5.h,
                ),
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
      ),
    );
  }

  bool changesMade() {
    if (widget.buyer == null) {
      return true;
    }

    if (_name != widget.buyer!.name) {
      return true;
    }

    if (_address != widget.buyer!.address) {
      return true;
    }

    if (_gst != widget.buyer!.gst) {
      return true;
    }

    if (_state != widget.buyer!.state) {
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
    // Create buyer
    if (widget.buyer == null) {
      action = "created";
      await Provider.of<DatabaseModel>(context, listen: false).createBuyer(
        name: _name,
        address: _address,
        gst: _gst,
        state: _state,
      );
    } else {
      action = "updated";
      await Provider.of<DatabaseModel>(context, listen: false).updateBuyer(
        buyer: widget.buyer!,
        name: _name,
        address: _address,
        gst: _gst,
        state: _state,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    context.showSnackBar(message: "Buyer $action");
    Navigator.of(context).pop();
  }

  void deleteBuyer() async {
    // Prompt user to confirm deletion
    final delete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Buyer"),
        content: const Text("Are you sure you want to delete this buyer?"),
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

    // Delete buyer from database
    await Provider.of<DatabaseModel>(context, listen: false)
        .deleteBuyer(widget.buyer!);

    if (!mounted) return;

    Navigator.of(context).pop();
    context.showSnackBar(message: "Buyer deleted");
    Navigator.of(context).pop();
  }
}

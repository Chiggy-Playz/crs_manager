import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../providers/database.dart';
import '../utils/extensions.dart';
import '../utils/widgets.dart';
import 'home.dart';
import 'loading.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String _host = "";
  String _key = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("CRS Manager"),
      ),
      body: loginConnectionInfoWidget(context),
    );
  }

  Container loginConnectionInfoWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(6.w),
      child: Card(
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(5.w),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Text(
                    "Enter connection info",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SizedBox(
                  height: 6.h,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Host",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a host";
                    }
                    return null;
                  },
                  onSaved: (newValue) => _host = newValue ?? "",
                ),
                SizedBox(
                  height: 3.h,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Key",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a key";
                    }
                    return null;
                  },
                  onSaved: (newValue) => _key = newValue ?? "",
                ),
                SizedBox(
                  height: 3.h,
                ),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).push(opaquePage(const LoadingPage()));
                        await _saveConnectionInfo();
                      },
                      child: const Text("Save"),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveConnectionInfo() async {
    // Validate and save form values
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    var db = Provider.of<DatabaseModel>(context, listen: false);
    // Get database model and connect
    try {
      await db.connect(_host, _key);
    } catch (e) {
      // Connection is invalid, show error
      context.showErrorSnackBar(
        message: "An error occurred. Make sure the connection info is correct.",
      );
      Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;

    context.showSnackBar(
      message: "Connection successful, loading data",
    );

    await Future.delayed(const Duration(milliseconds: 100));
    await db.loadCache();
    // Connection is valid, save connection info

    var box = await Hive.openBox("settings");
    box.put("host", _host);
    box.put("key", _key);
    await box.close();

    if (!mounted) return;
    // Pop loading screen
    Navigator.of(context).pop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }
}

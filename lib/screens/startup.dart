

import "../utils/exceptions.dart";

import "../providers/database.dart";
import "home.dart";
import "login.dart";
import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:provider/provider.dart";

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  Widget? destination;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      await _connectToDb();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => destination!,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _connectToDb() async {
    var db = Provider.of<DatabaseModel>(context, listen: false);

    // Check if supabase connection info is stored
    var box = Hive.box("settings");
    var host = await box.get("host");
    var key = await box.get("key");
    try {
      if (host != null && key != null) {
        await db.connect(
          host,
          key,
        );
      } else {
        throw DatabaseConnectionError();
      }
    } on DatabaseConnectionError {
      destination = const Login();
      return;
    }
    await db.loadCache();
    destination = const HomePage();
  }
}

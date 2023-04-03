import "dart:convert";
import "dart:io";
import "package:package_info_plus/package_info_plus.dart";
import "package:url_launcher/url_launcher.dart";

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
      if (Platform.isAndroid) {
        await _checkForUpdates();
      }
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

  Future<void> _checkForUpdates() async {
    // Get current version
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // Get latest release version
    String url =
        "https://api.github.com/repos/Chiggy-Playz/crs_manager/releases/latest";
    var http = HttpClient();
    String version = await http
        .getUrl(Uri.parse(url))
        .then((request) => request.close())
        .then((response) => response.transform(utf8.decoder).join())
        .then((json) => jsonDecode(json)['tag_name']);

    String latestVersionCode = version.split("+")[1];

    // Compare version and prompt for update
    if (latestVersionCode == packageInfo.buildNumber) {
      return;
    }

    if (!mounted) return;

    var response = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Update Available"),
        content: const Text(
          "A new version of CRS Manager is available. Do you want to update now?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Later"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Update"),
          ),
        ],
      ),
    );

    if (!response) {
      return;
    }

    // Open download link
    String downloadUrl =
        "https://github.com/Chiggy-Playz/crs_manager/releases/latest/download/app-release.apk";
    await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
  }
}

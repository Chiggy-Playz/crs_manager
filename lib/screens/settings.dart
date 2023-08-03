import 'package:crs_manager/providers/settings.dart';
import 'package:crs_manager/utils/extensions.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import "dart:convert";
import "dart:io";
import "package:package_info_plus/package_info_plus.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await launchUrl(
                  Uri.parse(
                      "https://github.com/Chiggy-Playz/crs_manager/commits/master"),
                  mode: LaunchMode.externalApplication);
            },
            tooltip: "View changes",
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: "Open downloads page",
            onPressed: () async {
              await launchUrl(
                  Uri.parse(
                      "https://github.com/Chiggy-Playz/crs_manager/releases"),
                  mode: LaunchMode.externalApplication);
            },
          ),
          IconButton(
            icon: const Icon(Icons.new_releases),
            tooltip: "Check for updates",
            onPressed: _checkForUpdates,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SpacedRow(
              widget1: Text(
                "Theme",
                style: font(24),
              ),
              widget2: DropdownButton<FlexScheme>(
                items: List.generate(
                  FlexScheme.values.length,
                  (index) => DropdownMenuItem(
                    value: FlexScheme.values[index],
                    child: Text(FlexScheme.values[index]
                        .toString()
                        .split(".")[1]
                        .capitalize),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<SettingsProvider>(context, listen: false)
                      .setTheme(value!);
                  var settingsBox = Hive.box("settings");
                  settingsBox.put("theme", FlexScheme.values.indexOf(value));
                },
              ),
            ),
            SizedBox(
              height: 2.h,
            ),
            SpacedRow(
              widget1: Text(
                "Theme Mode",
                style: font(24),
              ),
              widget2: DropdownButton<ThemeMode>(
                items: List.generate(
                  ThemeMode.values.length,
                  (index) => DropdownMenuItem(
                    value: ThemeMode.values[index],
                    child: Text(ThemeMode.values[index]
                        .toString()
                        .split(".")[1]
                        .capitalize),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<SettingsProvider>(context, listen: false)
                      .setThemeMode(value!);
                  var settingsBox = Hive.box("settings");
                  settingsBox.put("themeMode", ThemeMode.values.indexOf(value));
                },
              ),
            ),
          ],
        ),
      ),
    );
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

    if (!mounted) return;

    // Compare version and prompt for update
    if (latestVersionCode == packageInfo.buildNumber) {
      context.showSnackBar(message: "No updates available");
      return;
    }


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

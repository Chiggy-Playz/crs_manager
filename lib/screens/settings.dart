import 'package:crs_manager/providers/settings.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(title: const Text("Settings")),
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
}

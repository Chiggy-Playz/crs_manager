import 'dart:io';

import 'package:crs_manager/providers/drive.dart';
import 'package:crs_manager/providers/settings.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:provider/provider.dart';

import 'providers/database.dart';
import 'screens/startup.dart';

final GlobalKey<NavigatorState> navigatorState = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String path = (await getApplicationDocumentsDirectory()).path;
  
  if (!Platform.isAndroid) {
    // Append rough folder path to path
    path += "/CRSManagerRough";
  }
  Hive.init(path);
  await Hive.openBox("settings");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseModel()),
        ChangeNotifierProvider(create: (_) {
          Future.delayed(Duration.zero, () async {});
          var settingsBox = Hive.box("settings");
          var settings = SettingsProvider();
          settings.setTheme(
              FlexScheme.values[settingsBox.get("theme", defaultValue: 2)]);
          settings.setThemeMode(
              ThemeMode.values[settingsBox.get("themeMode", defaultValue: 2)]);
          return settings;
        }),
        Provider<DriveHandler>(
          create: (context) {
            var secrets =
                Provider.of<DatabaseModel>(context, listen: false).secrets;
            return DriveHandler(secrets: secrets["drive"]!);
          },
        )
      ],
      builder: (context, child) => ResponsiveSizer(
        builder: (p0, p1, p2) => Consumer<SettingsProvider>(
          builder: (context, settings, child) => MaterialApp(
            title: 'CRS Manager',
            theme: FlexThemeData.light(
              scheme: settings.theme,
              surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
              blendLevel: 9,
              subThemesData: const FlexSubThemesData(
                blendOnLevel: 10,
                blendOnColors: false,
                fabUseShape: true,
                fabSchemeColor: SchemeColor.primary,
                inputDecoratorRadius: 12,
              ),
              useMaterial3ErrorColors: true,
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
            ),
            darkTheme: FlexThemeData.dark(
              scheme: settings.theme,
              surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
              blendLevel: 15,
              subThemesData: const FlexSubThemesData(
                blendOnLevel: 20,
                fabUseShape: true,
                appBarBackgroundSchemeColor: SchemeColor.background,
                fabSchemeColor: SchemeColor.primary,
                inputDecoratorRadius: 12,
              ),
              useMaterial3ErrorColors: true,
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
            ),
            themeMode: settings.themeMode,
            home: const StartupPage(),
            navigatorKey: navigatorState,
          ),
        ),
      ),
    );
  }
}

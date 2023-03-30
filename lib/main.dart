import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:provider/provider.dart';

import 'providers/database.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  // Check if supabase connection info is stored
  var box = await Hive.openBox("settings");
  var host = await box.get("host");
  var key = await box.get("key");

  DatabaseModel database = DatabaseModel();

  if (host != null && key != null) {
    await database.connect(
      host,
      key,
    );
    await box.close();
  }

  runApp(
    MyApp(
      database: database,
    ),
  );
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  DatabaseModel database;

  MyApp({required this.database, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: database,
      child: ResponsiveSizer(
        builder: (p0, p1, p2) => MaterialApp(
          title: 'CRS Manager',
          theme: theme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          routes: {
            "/login": (context) => const Login(),
            "/home": (context) => const HomeWidget(),
          },
          initialRoute: database.connected ? "/home" : "/login",
        ),
      ),
    );
  }
}

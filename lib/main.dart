import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/home.dart';
import 'package:crs_manager/screens/login.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  // Check if supabase connection info is stored
  var box = await Hive.openBox("settings");
  var host = await box.get("host");
  var key = await box.get("key");

  DatabaseModel? database;

  if (host != null && key != null) {
    database = DatabaseModel();
    database.connect(
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
  DatabaseModel? database;

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
          initialRoute: database == null ? "/login" : "/home",
        ),
      ),
    );
  }
}

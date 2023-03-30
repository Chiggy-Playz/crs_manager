import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:provider/provider.dart';

import 'providers/database.dart';
import 'screens/startup.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseModel(),
      child: ResponsiveSizer(
        builder: (p0, p1, p2) => MaterialApp(
          title: 'CRS Manager',
          theme: theme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: const StartupPage(),
        ),
      ),
    );
  }
}

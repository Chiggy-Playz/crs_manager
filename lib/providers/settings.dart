import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  FlexScheme theme = FlexScheme.blue;
  ThemeMode themeMode = ThemeMode.dark;
  
  void setTheme(FlexScheme theme) {
    this.theme = theme;
    notifyListeners();
  }

  void setThemeMode(ThemeMode themeMode) {
    this.themeMode = themeMode;
    notifyListeners();
  }

}
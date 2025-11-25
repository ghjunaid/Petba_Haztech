import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'isLightTheme';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isLightMode => _themeMode == ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> toggleTheme() async {
    _themeMode = isLightMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isLightMode);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey);
    if (saved != null) {
      _themeMode = saved ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    }
  }
}







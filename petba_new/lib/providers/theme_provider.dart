import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'isLightTheme';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isInitialized => _isInitialized;

  Future<void> toggleTheme() async {
    _themeMode = isLightMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isLightMode);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool(_prefKey);
    if (savedValue != null) {
      _themeMode = savedValue ? ThemeMode.light : ThemeMode.dark;
    }
    _isInitialized = true;
    notifyListeners();
  }
}






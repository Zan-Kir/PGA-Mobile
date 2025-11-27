import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'pref_dark_mode';
  static const _fontKey = 'pref_font_scale';
  bool _isDark = false;
  double _fontScale = 1.0;

  bool get isDark => _isDark;
  double get fontScale => _fontScale;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    _fontScale = prefs.getDouble(_fontKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.7, 1.5);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontKey, _fontScale);
  }
}

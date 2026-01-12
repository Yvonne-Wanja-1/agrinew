import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;

  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'en';
  bool _isInitialized = false;

  // 🔍 GETTERS
  bool get darkModeEnabled => _darkModeEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedLanguage => _selectedLanguage;
  bool get isInitialized => _isInitialized;

  // 🚀 INITIALIZE
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _darkModeEnabled = _prefs.getBool('dark_mode') ?? false;
    _notificationsEnabled = _prefs.getBool('notifications') ?? true;
    _selectedLanguage = _prefs.getString('language') ?? 'en';

    _isInitialized = true;
    notifyListeners();
  }

  // 🌗 DARK MODE
  Future<void> setDarkMode(bool value) async {
    _darkModeEnabled = value;
    await _prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  // 🔔 NOTIFICATIONS
  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notifications', value);
    notifyListeners();
  }

  // 🌍 LANGUAGE
  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    await _prefs.setString('language', language);
    notifyListeners();
  }

  // 🌙 DARK THEME
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  // ☀️ LIGHT THEME
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F9F5),
    );
  }
}

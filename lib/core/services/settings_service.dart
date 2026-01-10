import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'en';
  bool _isInitialized = false;

  // Getters
  bool get darkModeEnabled => _darkModeEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedLanguage => _selectedLanguage;
  bool get isInitialized => _isInitialized;

  // Initialize settings
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _darkModeEnabled = _prefs.getBool('dark_mode') ?? false;
    _notificationsEnabled = _prefs.getBool('notifications') ?? true;
    _selectedLanguage = _prefs.getString('language') ?? 'en';
    _isInitialized = true;
    notifyListeners();
  }

  // Dark Mode Toggle
  Future<void> setDarkMode(bool value) async {
    _darkModeEnabled = value;
    await _prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  // Notifications Toggle
  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notifications', value);
    notifyListeners();
  }

  // Language Selection
  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    await _prefs.setString('language', language);
    notifyListeners();
  }

  // Get theme based on dark mode setting
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(color: Colors.grey.shade800, elevation: 1),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white70),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      dividerColor: Colors.grey.shade700,
    );
  }

  ThemeData getLightTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green.shade400,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F9F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(color: Colors.white, elevation: 2),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.black87),
        headlineMedium: TextStyle(color: Colors.black87),
        headlineSmall: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87),
        titleMedium: TextStyle(color: Colors.black87),
        titleSmall: TextStyle(color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
        labelLarge: TextStyle(color: Colors.black87),
        labelMedium: TextStyle(color: Colors.black87),
        labelSmall: TextStyle(color: Colors.black54),
      ),
      iconTheme: const IconThemeData(color: Colors.black54),
      dividerColor: Colors.grey.shade300,
    );
  }
}

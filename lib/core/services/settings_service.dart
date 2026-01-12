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
    print('🌓 [SETTINGS] Dark mode changed to: $value');
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
      canvasColor: const Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey.shade800,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.green.shade400,
        unselectedItemColor: Colors.white54,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green.shade600,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.green.shade600,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.green.shade600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.green.shade400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade400),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIconColor: Colors.white54,
        suffixIconColor: Colors.white54,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
      dialogBackgroundColor: Colors.grey.shade900,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade800,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.white),
        side: BorderSide(color: Colors.grey.shade700),
      ),
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
      canvasColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green.shade600,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.green.shade600,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade600,
          side: BorderSide(color: Colors.green.shade600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.green.shade600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade600),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIconColor: Colors.grey.shade600,
        suffixIconColor: Colors.grey.shade600,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
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
      dialogBackgroundColor: Colors.white,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade900,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        labelStyle: const TextStyle(color: Colors.black87),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}

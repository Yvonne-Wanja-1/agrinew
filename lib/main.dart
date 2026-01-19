import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/connectivity_listener.dart';
import 'core/services/settings_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load env FIRST
  await dotenv.load(fileName: ".env");

  // 🔍 DEBUG: Verify env vars are loaded
  debugPrint('🔍 SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  debugPrint(
    '🔍 SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY'] != null ? 'LOADED ✅' : 'MISSING ❌'}',
  );

  // ✅ Init Supabase EARLY and loudly (no silent fallback for now)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  debugPrint('✅ SUPABASE connected');

  // Initialize other services
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await LocalStorageService.initialize();
  await ConnectivityListener.initialize();
  await LocalNotificationService().initialize();
  await ConnectivityService().initialize();
  await AuthService.initialize();

  // ✅ SINGLE source of truth
  final settingsService = SettingsService();
  await settingsService.initialize();

  runApp(
    ChangeNotifierProvider<SettingsService>(
      create: (_) => settingsService,
      child: const AgriClinicHubApp(),
    ),
  );
}

class AgriClinicHubApp extends StatelessWidget {
  const AgriClinicHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, _) {
        return MaterialApp(
          title: 'Agri Clinic Hub',
          debugShowCheckedModeBanner: false,
          theme: settingsService.getLightTheme(),
          darkTheme: settingsService.getDarkTheme(),
          themeMode: settingsService.darkModeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRouter.splash,
        );
      },
    );
  }
}

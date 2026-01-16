import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/connectivity_listener.dart';
import 'core/services/settings_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await LocalStorageService.initialize();
  await ConnectivityListener.initialize();
  await LocalNotificationService().initialize();
  await ConnectivityService().initialize();
  await AuthService.initialize();

  // Initialize Supabase (handles initialization errors gracefully)
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint(
      '⚠️ [MAIN] Supabase initialization failed (will use local storage only): $e',
    );
  }

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

          // 🌗 THEMES
          theme: settingsService.getLightTheme(),
          darkTheme: settingsService.getDarkTheme(),
          themeMode: settingsService.darkModeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,

          // 🧭 ROUTING
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRouter.login,
        );
      },
    );
  }
}

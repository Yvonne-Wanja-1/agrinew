import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/connectivity_listener.dart';
import 'core/services/settings_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await LocalStorageService.initialize();
  await ConnectivityListener.initialize();
  await SettingsService().initialize();
  await LocalNotificationService().initialize();
  await ConnectivityService().initialize();
  runApp(const AgriClinicHubApp());
}

class AgriClinicHubApp extends StatelessWidget {
  const AgriClinicHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsService(),
      child: Consumer<SettingsService>(
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
            initialRoute: AppRouter.login,
          );
        },
      ),
    );
  }
}

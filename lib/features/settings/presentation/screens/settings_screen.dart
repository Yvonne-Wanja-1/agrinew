import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
          final shadowColor = isDarkMode
              ? Colors.grey.shade700
              : Colors.green.shade400;
          final iconColor = isDarkMode
              ? Colors.green.shade300
              : Colors.green.shade600;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // App Preferences Section
                  _buildSectionTitle(context, 'Preferences'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.language, color: iconColor),
                          title: Text(
                            'Language',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            settingsService.selectedLanguage == 'en'
                                ? 'English'
                                : 'Kiswahili',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _showLanguageDialog(context, settingsService),
                        ),
                        Divider(
                          height: 0,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        ListTile(
                          leading: Icon(
                            settingsService.darkModeEnabled
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: iconColor,
                          ),
                          title: Text(
                            'Dark Mode',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Switch(
                            value: settingsService.darkModeEnabled,
                            onChanged: (value) async {
                              await settingsService.setDarkMode(value);
                            },
                            activeColor: Colors.green.shade400,
                          ),
                        ),
                        Divider(
                          height: 0,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        ListTile(
                          leading: Icon(Icons.notifications, color: iconColor),
                          title: Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Switch(
                            value: settingsService.notificationsEnabled,
                            onChanged: (value) async {
                              await settingsService.setNotifications(value);
                            },
                            activeColor: Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Data Section
                  _buildSectionTitle(context, 'Data'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.storage, color: iconColor),
                          title: Text(
                            'Cache Size',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '2.3 MB',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache cleared')),
                            );
                          },
                        ),
                        Divider(
                          height: 0,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        ListTile(
                          leading: Icon(Icons.backup, color: iconColor),
                          title: Text(
                            'Backup Data',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup in progress'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // About Section
                  _buildSectionTitle(context, 'About'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.info, color: iconColor),
                          title: Text(
                            'Version',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '1.0.0',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                        Divider(
                          height: 0,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        ListTile(
                          leading: Icon(Icons.description, color: iconColor),
                          title: Text(
                            'Privacy Policy',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening privacy policy'),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 0,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        ListTile(
                          leading: Icon(Icons.assignment, color: iconColor),
                          title: Text(
                            'Terms of Service',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening terms of service'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Account Section
                  _buildSectionTitle(context, 'Account'),
                  const SizedBox(height: 12),
                  Card(
                    color: cardColor,
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red.shade600),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleLogout(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.green.shade600,
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('English'),
              value: 'en',
              groupValue: settingsService.selectedLanguage,
              onChanged: (value) async {
                await settingsService.setLanguage(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Kiswahili'),
              value: 'sw',
              groupValue: settingsService.selectedLanguage,
              onChanged: (value) async {
                await settingsService.setLanguage(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // Call AuthService to logout and clear session
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade400,
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Language',
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: settingsService.selectedLanguage == 'en'
                              ? const Text(
                                  'English',
                                  style: TextStyle(color: Colors.black54),
                                )
                              : const Text(
                                  'Kiswahili',
                                  style: TextStyle(color: Colors.black54),
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _showLanguageDialog(context, settingsService),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: Icon(
                            settingsService.darkModeEnabled
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Dark Mode',
                            style: TextStyle(color: Colors.black),
                          ),
                          trailing: Switch(
                            value: settingsService.darkModeEnabled,
                            onChanged: (value) async {
                              await settingsService.setDarkMode(value);
                            },
                            activeColor: Colors.green.shade600,
                          ),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: Icon(
                            Icons.notifications,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Notifications',
                            style: TextStyle(color: Colors.black),
                          ),
                          trailing: Switch(
                            value: settingsService.notificationsEnabled,
                            onChanged: (value) async {
                              await settingsService.setNotifications(value);
                            },
                            activeColor: Colors.green.shade600,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade400,
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.storage,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Cache Size',
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: const Text(
                            '2.3 MB',
                            style: TextStyle(color: Colors.black54),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache cleared')),
                            );
                          },
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: Icon(
                            Icons.backup,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Backup Data',
                            style: TextStyle(color: Colors.black),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade400,
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.info,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Version',
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: const Text(
                            '1.0.0',
                            style: TextStyle(color: Colors.black54),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: Icon(
                            Icons.description,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Privacy Policy',
                            style: TextStyle(color: Colors.black),
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
                        const Divider(height: 0),
                        ListTile(
                          leading: Icon(
                            Icons.assignment,
                            color: Colors.green.shade600,
                          ),
                          title: const Text(
                            'Terms of Service',
                            style: TextStyle(color: Colors.black),
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

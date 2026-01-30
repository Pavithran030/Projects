import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedTheme = 'dark';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _selectedTheme = prefs.getString(StorageKeys.themeMode) ?? 'dark';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setString(StorageKeys.themeMode, _selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notifications section
                      _buildSectionHeader('Notifications')
                          .animate()
                          .fadeIn(duration: 500.ms),
                      
                      const SizedBox(height: 12),

                      _buildSettingsCard([
                        _buildSwitchTile(
                          'Push Notifications',
                          'Receive attendance reminders',
                          Icons.notifications_outlined,
                          _notificationsEnabled,
                          (value) {
                            setState(() => _notificationsEnabled = value);
                            _saveSettings();
                          },
                        ),
                        _buildDivider(),
                        _buildSwitchTile(
                          'Sound',
                          'Play sound on check-in/out',
                          Icons.volume_up_outlined,
                          _soundEnabled,
                          (value) {
                            setState(() => _soundEnabled = value);
                            _saveSettings();
                          },
                        ),
                        _buildDivider(),
                        _buildSwitchTile(
                          'Vibration',
                          'Vibrate on successful scan',
                          Icons.vibration,
                          _vibrationEnabled,
                          (value) {
                            setState(() => _vibrationEnabled = value);
                            _saveSettings();
                          },
                        ),
                      ])
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Appearance section
                      _buildSectionHeader('Appearance')
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms),
                      
                      const SizedBox(height: 12),

                      _buildSettingsCard([
                        _buildThemeSelector(),
                      ])
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Security section
                      _buildSectionHeader('Security')
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 500.ms),
                      
                      const SizedBox(height: 12),

                      _buildSettingsCard([
                        _buildNavigationTile(
                          'Change Password',
                          'Update your account password',
                          Icons.lock_outline,
                          () {
                            // TODO: Navigate to change password
                            _showComingSoon();
                          },
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          'Face Data',
                          'Manage registered face data',
                          Icons.face_retouching_natural_rounded,
                          () {
                            Navigator.pushNamed(context, Routes.faceRegistration);
                          },
                        ),
                      ])
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // About section
                      _buildSectionHeader('About')
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 500.ms),
                      
                      const SizedBox(height: 12),

                      _buildSettingsCard([
                        _buildInfoTile(
                          'Version',
                          AppMetadata.appVersion,
                          Icons.info_outline,
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          'Privacy Policy',
                          'Read our privacy policy',
                          Icons.privacy_tip_outlined,
                          () => _showComingSoon(),
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          'Terms of Service',
                          'Read our terms of service',
                          Icons.description_outlined,
                          () => _showComingSoon(),
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          'Help & Support',
                          'Get help with the app',
                          Icons.help_outline,
                          () => _showComingSoon(),
                        ),
                      ])
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 40),

                      // App info
                      Center(
                        child: Column(
                          children: [
                            Text(
                              AppMetadata.appName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.grey500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Made with ❤️ by ${AppMetadata.developerName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey600,
                                  ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 500.ms),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.grey400,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey400),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.grey500, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey400),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.grey500, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey600,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey400),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.white),
      ),
      trailing: Text(
        value,
        style: const TextStyle(color: AppColors.grey400),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: AppColors.grey400),
              const SizedBox(width: 16),
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOption('Light', 'light', Icons.light_mode),
              const SizedBox(width: 12),
              _buildThemeOption('Dark', 'dark', Icons.dark_mode),
              const SizedBox(width: 12),
              _buildThemeOption('System', 'system', Icons.settings_suggest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, String value, IconData icon) {
    final isSelected = _selectedTheme == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTheme = value);
          _saveSettings();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey700,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.grey400,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: AppColors.grey800,
      indent: 56,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

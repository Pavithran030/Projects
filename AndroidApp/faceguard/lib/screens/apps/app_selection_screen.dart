import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart' as installed_apps;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/app_limit_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Screen for selecting apps to set time limits
class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  List<installed_apps.AppInfo> _installedApps = [];
  List<installed_apps.AppInfo> _filteredApps = [];
  Set<String> _selectedPackages = {};
  Set<String> _alreadyLimitedPackages = {};
  bool _isLoading = true;
  bool _showSystemApps = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _loadExistingLimits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLimits() async {
    final authService = context.read<AuthService>();
    final dbService = context.read<DatabaseService>();
    
    if (authService.currentUser != null) {
      final existingLimits = await dbService.getAppLimits(authService.currentUser!.id);
      setState(() {
        _alreadyLimitedPackages = existingLimits.map((e) => e.packageName).toSet();
      });
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      
      // Sort by app name
      apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      
      setState(() {
        _installedApps = apps;
        _filterApps();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredApps = _installedApps.where((app) {
        // Filter by search query
        final matchesSearch = app.name?.toLowerCase().contains(query) ?? false;
        
        // Filter system apps if needed
        if (!_showSystemApps) {
          // Exclude common system packages
          final isSystemApp = app.packageName?.startsWith('com.android.') == true ||
              app.packageName?.startsWith('com.google.android.') == true ||
              app.packageName == 'com.example.faceguard';
          if (isSystemApp) return false;
        }
        
        // Exclude already limited apps
        if (_alreadyLimitedPackages.contains(app.packageName)) {
          return false;
        }
        
        return matchesSearch || query.isEmpty;
      }).toList();
    });
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  Future<void> _proceedToSetTimer() async {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one app')),
      );
      return;
    }

    // Get selected apps info
    final selectedApps = _installedApps
        .where((app) => _selectedPackages.contains(app.packageName))
        .toList();

    // Show timer setup dialog
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TimerSetupSheet(
        selectedAppsCount: selectedApps.length,
      ),
    );

    if (result != null && result > 0) {
      await _saveAppLimits(selectedApps, result);
    }
  }

  Future<void> _saveAppLimits(List<installed_apps.AppInfo> apps, int dailyLimitMinutes) async {
    final authService = context.read<AuthService>();
    final dbService = context.read<DatabaseService>();
    
    if (authService.currentUser == null) return;

    final userId = authService.currentUser!.id;
    final uuid = const Uuid();

    for (final app in apps) {
      final appLimit = AppLimitModel(
        id: uuid.v4(),
        packageName: app.packageName ?? '',
        appName: app.name ?? 'Unknown',
        appIcon: app.icon != null ? Uint8List.fromList(app.icon!) : null,
        dailyLimitMinutes: dailyLimitMinutes,
      );

      await dbService.insertAppLimit(userId, appLimit);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${apps.length} app(s) with ${dailyLimitMinutes}min daily limit'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate apps were added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Select Apps'),
        actions: [
          if (_selectedPackages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_selectedPackages.length} selected',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterApps(),
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: AppColors.grey500),
                prefixIcon: const Icon(Icons.search, color: AppColors.grey400),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.grey400),
                        onPressed: () {
                          _searchController.clear();
                          _filterApps();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Show system apps toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Show system apps',
                  style: TextStyle(color: AppColors.grey400),
                ),
                const Spacer(),
                Switch(
                  value: _showSystemApps,
                  onChanged: (value) {
                    setState(() {
                      _showSystemApps = value;
                      _filterApps();
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Apps list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apps_outlined,
                              size: 64,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No apps found',
                              style: TextStyle(
                                color: AppColors.grey400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final isSelected = _selectedPackages.contains(app.packageName);

                          return _AppListTile(
                            app: app,
                            isSelected: isSelected,
                            onTap: () => _toggleSelection(app.packageName ?? ''),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedPackages.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _proceedToSetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Set Timer for ${_selectedPackages.length} App(s)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// List tile for displaying app info
class _AppListTile extends StatelessWidget {
  final installed_apps.AppInfo app;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppListTile({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: app.icon != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    Uint8List.fromList(app.icon!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  Icons.android,
                  color: AppColors.grey400,
                  size: 28,
                ),
        ),
        title: Text(
          app.name ?? 'Unknown',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          app.packageName ?? '',
          style: const TextStyle(
            color: AppColors.grey500,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey600,
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 16,
                )
              : null,
        ),
      ),
    );
  }
}

/// Bottom sheet for setting timer duration
class _TimerSetupSheet extends StatefulWidget {
  final int selectedAppsCount;

  const _TimerSetupSheet({required this.selectedAppsCount});

  @override
  State<_TimerSetupSheet> createState() => _TimerSetupSheetState();
}

class _TimerSetupSheetState extends State<_TimerSetupSheet> {
  int _hours = 1;
  int _minutes = 0;

  int get _totalMinutes => (_hours * 60) + _minutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Set Daily Time Limit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For ${widget.selectedAppsCount} selected app(s)',
            style: const TextStyle(
              color: AppColors.grey400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Time picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              _TimerPicker(
                value: _hours,
                maxValue: 23,
                label: 'Hours',
                onChanged: (value) => setState(() => _hours = value),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              // Minutes
              _TimerPicker(
                value: _minutes,
                maxValue: 59,
                step: 5,
                label: 'Minutes',
                onChanged: (value) => setState(() => _minutes = value),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick select buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickSelectChip(
                label: '30m',
                isSelected: _totalMinutes == 30,
                onTap: () => setState(() {
                  _hours = 0;
                  _minutes = 30;
                }),
              ),
              _QuickSelectChip(
                label: '1h',
                isSelected: _totalMinutes == 60,
                onTap: () => setState(() {
                  _hours = 1;
                  _minutes = 0;
                }),
              ),
              _QuickSelectChip(
                label: '2h',
                isSelected: _totalMinutes == 120,
                onTap: () => setState(() {
                  _hours = 2;
                  _minutes = 0;
                }),
              ),
              _QuickSelectChip(
                label: '3h',
                isSelected: _totalMinutes == 180,
                onTap: () => setState(() {
                  _hours = 3;
                  _minutes = 0;
                }),
              ),
              _QuickSelectChip(
                label: '4h',
                isSelected: _totalMinutes == 240,
                onTap: () => setState(() {
                  _hours = 4;
                  _minutes = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _totalMinutes > 0
                  ? () => Navigator.pop(context, _totalMinutes)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _totalMinutes > 0
                    ? 'Set ${_hours > 0 ? "${_hours}h " : ""}${_minutes > 0 ? "${_minutes}m" : ""} Limit'
                    : 'Select a time',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Timer value picker widget
class _TimerPicker extends StatelessWidget {
  final int value;
  final int maxValue;
  final int step;
  final String label;
  final ValueChanged<int> onChanged;

  const _TimerPicker({
    required this.value,
    required this.maxValue,
    this.step = 1,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Increment button
              IconButton(
                onPressed: value < maxValue
                    ? () => onChanged((value + step).clamp(0, maxValue))
                    : null,
                icon: const Icon(Icons.keyboard_arrow_up),
                color: AppColors.white,
              ),
              // Value display
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  value.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              // Decrement button
              IconButton(
                onPressed: value > 0
                    ? () => onChanged((value - step).clamp(0, maxValue))
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down),
                color: AppColors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Quick select time chip
class _QuickSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

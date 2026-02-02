import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/app_limit_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Screen showing all apps with time limits
class AppLimitsScreen extends StatefulWidget {
  const AppLimitsScreen({super.key});

  @override
  State<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends State<AppLimitsScreen> {
  List<AppLimitModel> _appLimits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppLimits();
  }

  Future<void> _loadAppLimits() async {
    final authService = context.read<AuthService>();
    final dbService = context.read<DatabaseService>();
    
    if (authService.currentUser != null) {
      final limits = await dbService.getAppLimits(authService.currentUser!.id);
      setState(() {
        _appLimits = limits;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAppSelection() async {
    final result = await Navigator.pushNamed(context, Routes.appSelection);
    if (result == true) {
      _loadAppLimits(); // Reload after adding new apps
    }
  }

  Future<void> _deleteAppLimit(AppLimitModel appLimit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Remove App Limit',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Remove time limit for ${appLimit.appName}?',
          style: const TextStyle(color: AppColors.grey400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dbService = context.read<DatabaseService>();
      await dbService.deleteAppLimit(appLimit.id);
      _loadAppLimits();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLimit.appName} removed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _editTimeLimit(AppLimitModel appLimit) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditTimerSheet(
        appName: appLimit.appName,
        currentMinutes: appLimit.dailyLimitMinutes,
      ),
    );

    if (result != null && result > 0) {
      final dbService = context.read<DatabaseService>();
      final updated = appLimit.copyWith(dailyLimitMinutes: result);
      await dbService.updateAppLimit(updated);
      _loadAppLimits();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLimit.appName} limit updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleAppLimit(AppLimitModel appLimit) async {
    final dbService = context.read<DatabaseService>();
    await dbService.toggleAppLimit(appLimit.id, !appLimit.isEnabled);
    _loadAppLimits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('App Time Limits'),
        actions: [
          IconButton(
            onPressed: _loadAppLimits,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _appLimits.isEmpty
              ? _buildEmptyState()
              : _buildAppsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAppSelection,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Add Apps',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No App Limits Set',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add apps to monitor and limit\nyour daily usage time',
              style: TextStyle(
                color: AppColors.grey400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAppSelection,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsList() {
    // Separate enabled and disabled apps
    final enabledApps = _appLimits.where((a) => a.isEnabled).toList();
    final disabledApps = _appLimits.where((a) => !a.isEnabled).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        _buildSummaryCard(),
        const SizedBox(height: 24),

        // Active apps
        if (enabledApps.isNotEmpty) ...[
          const Text(
            'ACTIVE LIMITS',
            style: TextStyle(
              color: AppColors.grey500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...enabledApps.map((app) => _AppLimitCard(
                appLimit: app,
                onEdit: () => _editTimeLimit(app),
                onDelete: () => _deleteAppLimit(app),
                onToggle: () => _toggleAppLimit(app),
              )),
        ],

        // Disabled apps
        if (disabledApps.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'PAUSED',
            style: TextStyle(
              color: AppColors.grey500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...disabledApps.map((app) => _AppLimitCard(
                appLimit: app,
                onEdit: () => _editTimeLimit(app),
                onDelete: () => _deleteAppLimit(app),
                onToggle: () => _toggleAppLimit(app),
              )),
        ],

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalApps = _appLimits.length;
    final activeApps = _appLimits.where((a) => a.isEnabled).length;
    final totalLimitMinutes = _appLimits.fold<int>(
      0,
      (sum, app) => sum + app.dailyLimitMinutes,
    );
    final totalUsedMinutes = _appLimits.fold<int>(
      0,
      (sum, app) => sum + app.usedTodayMinutes,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Today\'s Overview',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Apps',
                  value: '$activeApps/$totalApps',
                  icon: Icons.apps,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Used Today',
                  value: _formatMinutes(totalUsedMinutes),
                  icon: Icons.timer,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Total Limit',
                  value: _formatMinutes(totalLimitMinutes),
                  icon: Icons.hourglass_bottom,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}

/// Summary item widget
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Card displaying individual app limit
class _AppLimitCard extends StatelessWidget {
  final AppLimitModel appLimit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _AppLimitCard({
    required this.appLimit,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = appLimit.isLimitExceeded;
    final progressColor = isOverLimit
        ? AppColors.error
        : appLimit.usagePercentage > 0.8
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: appLimit.isEnabled
            ? null
            : Border.all(color: AppColors.grey700),
      ),
      child: Opacity(
        opacity: appLimit.isEnabled ? 1.0 : 0.6,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: appLimit.appIcon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          appLimit.appIcon!,
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
                appLimit.appName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${appLimit.formattedUsed} / ${appLimit.formattedLimit}',
                style: TextStyle(
                  color: isOverLimit ? AppColors.error : AppColors.grey400,
                  fontSize: 13,
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.grey400),
                color: AppColors.surfaceDark,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'toggle':
                      onToggle();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.grey400, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Time', style: TextStyle(color: AppColors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          appLimit.isEnabled ? Icons.pause : Icons.play_arrow,
                          color: AppColors.grey400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          appLimit.isEnabled ? 'Pause' : 'Resume',
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error, size: 20),
                        SizedBox(width: 12),
                        Text('Remove', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: appLimit.usagePercentage,
                      backgroundColor: AppColors.grey800,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appLimit.formattedRemaining,
                        style: TextStyle(
                          color: isOverLimit ? AppColors.error : AppColors.grey500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(appLimit.usagePercentage * 100).toInt()}%',
                        style: TextStyle(
                          color: progressColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for editing timer
class _EditTimerSheet extends StatefulWidget {
  final String appName;
  final int currentMinutes;

  const _EditTimerSheet({
    required this.appName,
    required this.currentMinutes,
  });

  @override
  State<_EditTimerSheet> createState() => _EditTimerSheetState();
}

class _EditTimerSheetState extends State<_EditTimerSheet> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.currentMinutes ~/ 60;
    _minutes = widget.currentMinutes % 60;
  }

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
            'Edit Time Limit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.appName,
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
              Column(
                children: [
                  IconButton(
                    onPressed: _hours < 23
                        ? () => setState(() => _hours++)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    color: AppColors.white,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _hours.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _hours > 0
                        ? () => setState(() => _hours--)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    color: AppColors.white,
                  ),
                  const Text(
                    'Hours',
                    style: TextStyle(color: AppColors.grey400),
                  ),
                ],
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
              Column(
                children: [
                  IconButton(
                    onPressed: _minutes < 55
                        ? () => setState(() => _minutes += 5)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    color: AppColors.white,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _minutes.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _minutes > 0
                        ? () => setState(() => _minutes -= 5)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    color: AppColors.white,
                  ),
                  const Text(
                    'Minutes',
                    style: TextStyle(color: AppColors.grey400),
                  ),
                ],
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
              child: const Text(
                'Save Changes',
                style: TextStyle(
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

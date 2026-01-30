import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/attendance_model.dart';

/// Main dashboard screen after login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  int _currentIndex = 0;
  AttendanceModel? _todayCheckIn;
  AttendanceModel? _todayCheckOut;
  Map<String, int> _attendanceStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id ?? '';
      
      // Load today's attendance
      _todayCheckIn = await _databaseService.getTodayCheckIn(userId);
      _todayCheckOut = await _databaseService.getTodayCheckOut(userId);

      // Load stats for this month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      _attendanceStats = await _databaseService.getAttendanceStats(
        userId,
        startOfMonth,
        now,
      );
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboard(),
              _buildHistoryPlaceholder(),
              _buildProfilePlaceholder(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, Routes.markAttendance).then((_) {
                  _loadData();
                });
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.face_retouching_natural_rounded),
              label: const Text('Mark Attendance'),
            )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 1, end: 0)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboard() {
    final user = _authService.currentUser;
    final greeting = _getGreeting();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey400,
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .scale(),
              ],
            ),

            const SizedBox(height: 30),

            // Today's status card
            _buildTodayStatusCard()
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 20),

            // Quick stats
            Text(
              'This Month',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                  ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),

            const SizedBox(height: 16),

            _buildStatsGrid()
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Attendance chart
            Text(
              'Weekly Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                  ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 500.ms),

            const SizedBox(height: 16),

            _buildWeeklyChart()
                .animate()
                .fadeIn(delay: 800.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    final hasCheckedIn = _todayCheckIn != null;
    final hasCheckedOut = _todayCheckOut != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: hasCheckedIn ? AppColors.successGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasCheckedIn ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(hasCheckedIn, hasCheckedOut),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeColumn(
                  'Check In',
                  _todayCheckIn?.formattedTime ?? '--:--',
                  Icons.login_rounded,
                  hasCheckedIn,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildTimeColumn(
                  'Check Out',
                  _todayCheckOut?.formattedTime ?? '--:--',
                  Icons.logout_rounded,
                  hasCheckedOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon, bool isComplete) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.white.withValues(alpha: isComplete ? 1.0 : 0.5),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Present',
          '${_attendanceStats['present'] ?? 0}',
          Icons.check_circle_outline,
          AppColors.success,
        ),
        _buildStatCard(
          'Late',
          '${_attendanceStats['late'] ?? 0}',
          Icons.schedule,
          AppColors.warning,
        ),
        _buildStatCard(
          'Absent',
          '${_attendanceStats['absent'] ?? 0}',
          Icons.cancel_outlined,
          AppColors.error,
        ),
        _buildStatCard(
          'Total Days',
          '${_attendanceStats['total'] ?? 0}',
          Icons.calendar_today,
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey400,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[value.toInt() % 7],
                      style: TextStyle(
                        color: AppColors.grey500,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    // Sample data - replace with actual data from database
    final data = [8.0, 9.0, 8.5, 7.0, 9.0, 0.0, 0.0];
    
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index],
            color: index < 5 ? AppColors.primary : AppColors.grey600,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildHistoryPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            'Attendance History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.attendanceHistory);
            },
            child: const Text('View Full History'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    final user = _authService.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              (user?.name ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey400,
                ),
          ),
          if (user?.department != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.department!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ],
          const SizedBox(height: 40),
          _buildProfileOption(
            Icons.person_outline,
            'Edit Profile',
            () => Navigator.pushNamed(context, Routes.profile),
          ),
          _buildProfileOption(
            Icons.face_retouching_natural_rounded,
            'Re-register Face',
            () => Navigator.pushNamed(context, Routes.faceRegistration),
          ),
          _buildProfileOption(
            Icons.settings_outlined,
            'Settings',
            () => Navigator.pushNamed(context, Routes.settings),
          ),
          _buildProfileOption(
            Icons.logout,
            'Logout',
            _handleLogout,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.grey400),
      title: Text(
        title,
        style: TextStyle(color: color ?? AppColors.white),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? AppColors.grey600,
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getStatusText(bool checkedIn, bool checkedOut) {
    if (checkedOut) return 'Complete';
    if (checkedIn) return 'Checked In';
    return 'Not Checked In';
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
              ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey400,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }
  }
}

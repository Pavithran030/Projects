import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/attendance_model.dart';

/// Screen displaying attendance history
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id ?? '';
      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

      _attendanceList = await _databaseService.getAttendanceForDateRange(
        userId,
        startOfMonth,
        endOfMonth,
      );
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }

    setState(() => _isLoading = false);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadAttendance();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });
      _loadAttendance();
    }
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
                        'Attendance History',
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

              // Month selector
              _buildMonthSelector()
                  .animate()
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 16),

              // Summary cards
              _buildSummaryCards()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Attendance list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _attendanceList.isEmpty
                        ? _buildEmptyState()
                        : _buildAttendanceList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final canGoNext = _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, color: AppColors.white),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            onPressed: canGoNext ? _nextMonth : null,
            icon: Icon(
              Icons.chevron_right,
              color: canGoNext ? AppColors.white : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Calculate summary from attendance list
    int checkIns = 0;
    int lateArrivals = 0;

    final processedDays = <String>{};
    for (final attendance in _attendanceList) {
      final dayKey = DateFormat('yyyy-MM-dd').format(attendance.timestamp);
      if (attendance.type == AttendanceType.checkIn && !processedDays.contains(dayKey)) {
        processedDays.add(dayKey);
        checkIns++;
        if (attendance.status == AttendanceStatus.late) {
          lateArrivals++;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Days Present',
              '$checkIns',
              Icons.check_circle_outline,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Late Arrivals',
              '$lateArrivals',
              Icons.schedule,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Records',
              '${_attendanceList.length}',
              Icons.receipt_long,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey400,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey400,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No records found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Group attendance by date
    final groupedAttendance = <String, List<AttendanceModel>>{};
    for (final attendance in _attendanceList) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.timestamp);
      groupedAttendance.putIfAbsent(dateKey, () => []);
      groupedAttendance[dateKey]!.add(attendance);
    }

    final dates = groupedAttendance.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateKey = dates[index];
        final records = groupedAttendance[dateKey]!;
        final date = DateTime.parse(dateKey);

        return _buildDayCard(date, records, index)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildDayCard(DateTime date, List<AttendanceModel> records, int index) {
    final checkIn = records.where((r) => r.type == AttendanceType.checkIn).firstOrNull;
    final checkOut = records.where((r) => r.type == AttendanceType.checkOut).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                            ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(checkIn?.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  'Check In',
                  checkIn?.formattedTime ?? '--:--',
                  Icons.login_rounded,
                  AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.grey700,
              ),
              Expanded(
                child: _buildTimeInfo(
                  'Check Out',
                  checkOut?.formattedTime ?? '--:--',
                  Icons.logout_rounded,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceStatus? status) {
    if (status == null) return const SizedBox();

    Color color;
    String text;

    switch (status) {
      case AttendanceStatus.present:
        color = AppColors.success;
        text = 'Present';
        break;
      case AttendanceStatus.late:
        color = AppColors.warning;
        text = 'Late';
        break;
      case AttendanceStatus.absent:
        color = AppColors.error;
        text = 'Absent';
        break;
      case AttendanceStatus.halfDay:
        color = AppColors.info;
        text = 'Half Day';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

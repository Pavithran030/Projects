import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Status badge widget for displaying attendance status
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  /// Factory for present status
  factory StatusBadge.present() => const StatusBadge(
        text: 'Present',
        color: AppColors.success,
        icon: Icons.check_circle_outline,
      );

  /// Factory for late status
  factory StatusBadge.late() => const StatusBadge(
        text: 'Late',
        color: AppColors.warning,
        icon: Icons.schedule,
      );

  /// Factory for absent status
  factory StatusBadge.absent() => const StatusBadge(
        text: 'Absent',
        color: AppColors.error,
        icon: Icons.cancel_outlined,
      );

  /// Factory for half-day status
  factory StatusBadge.halfDay() => const StatusBadge(
        text: 'Half Day',
        color: AppColors.info,
        icon: Icons.timelapse,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

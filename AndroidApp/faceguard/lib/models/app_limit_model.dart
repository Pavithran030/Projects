import 'dart:typed_data';

/// Model representing an app with time limit settings
class AppLimitModel {
  final String id;
  final String packageName;
  final String appName;
  final Uint8List? appIcon;
  final int dailyLimitMinutes; // Daily time limit in minutes
  final int usedTodayMinutes; // Time used today in minutes
  final bool isEnabled;
  final DateTime? lastResetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppLimitModel({
    required this.id,
    required this.packageName,
    required this.appName,
    this.appIcon,
    required this.dailyLimitMinutes,
    this.usedTodayMinutes = 0,
    this.isEnabled = true,
    this.lastResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if time limit is exceeded
  bool get isLimitExceeded => usedTodayMinutes >= dailyLimitMinutes;

  /// Get remaining time in minutes
  int get remainingMinutes {
    final remaining = dailyLimitMinutes - usedTodayMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Get usage percentage (0.0 to 1.0)
  double get usagePercentage {
    if (dailyLimitMinutes == 0) return 0.0;
    final percentage = usedTodayMinutes / dailyLimitMinutes;
    return percentage > 1.0 ? 1.0 : percentage;
  }

  /// Format time limit for display
  String get formattedLimit {
    final hours = dailyLimitMinutes ~/ 60;
    final minutes = dailyLimitMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Format used time for display
  String get formattedUsed {
    final hours = usedTodayMinutes ~/ 60;
    final minutes = usedTodayMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Format remaining time for display
  String get formattedRemaining {
    final remaining = remainingMinutes;
    final hours = remaining ~/ 60;
    final minutes = remaining % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m left';
    } else if (hours > 0) {
      return '${hours}h left';
    } else if (minutes > 0) {
      return '${minutes}m left';
    } else {
      return 'Time up!';
    }
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'appIcon': appIcon,
      'dailyLimitMinutes': dailyLimitMinutes,
      'usedTodayMinutes': usedTodayMinutes,
      'isEnabled': isEnabled ? 1 : 0,
      'lastResetDate': lastResetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory AppLimitModel.fromMap(Map<String, dynamic> map) {
    return AppLimitModel(
      id: map['id'] as String,
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      appIcon: map['appIcon'] as Uint8List?,
      dailyLimitMinutes: map['dailyLimitMinutes'] as int,
      usedTodayMinutes: map['usedTodayMinutes'] as int? ?? 0,
      isEnabled: map['isEnabled'] == 1,
      lastResetDate: map['lastResetDate'] != null
          ? DateTime.parse(map['lastResetDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Copy with new values
  AppLimitModel copyWith({
    String? id,
    String? packageName,
    String? appName,
    Uint8List? appIcon,
    int? dailyLimitMinutes,
    int? usedTodayMinutes,
    bool? isEnabled,
    DateTime? lastResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppLimitModel(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      appIcon: appIcon ?? this.appIcon,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedTodayMinutes: usedTodayMinutes ?? this.usedTodayMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Model for displaying installed apps (before adding limit)
class InstalledAppInfo {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final bool isSystemApp;

  InstalledAppInfo({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isSystemApp = false,
  });
}

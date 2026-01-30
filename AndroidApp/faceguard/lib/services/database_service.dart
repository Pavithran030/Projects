import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/face_data_model.dart';
import '../models/app_limit_model.dart';

/// Database service for local data persistence
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.usersTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        department TEXT,
        designation TEXT,
        profile_image_path TEXT,
        password_hash TEXT NOT NULL,
        is_face_registered INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.attendanceTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        location TEXT,
        latitude REAL,
        longitude REAL,
        face_image_path TEXT,
        confidence_score REAL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Face data table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.faceDataTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        embedding TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id)
      )
    ''');

    // Create indexes for faster queries
    await db.execute(
      'CREATE INDEX idx_attendance_user_id ON ${DatabaseConstants.attendanceTable} (user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_timestamp ON ${DatabaseConstants.attendanceTable} (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_face_data_user_id ON ${DatabaseConstants.faceDataTable} (user_id)',
    );

    // App limits table for app usage tracking
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.appLimitsTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        app_icon BLOB,
        daily_limit_minutes INTEGER NOT NULL,
        used_today_minutes INTEGER DEFAULT 0,
        is_enabled INTEGER DEFAULT 1,
        last_reset_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id),
        UNIQUE (user_id, package_name)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_app_limits_user_id ON ${DatabaseConstants.appLimitsTable} (user_id)',
    );
  }

  /// Handle database upgrades
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here when database schema changes
    if (oldVersion < 2) {
      // Add app_limits table for version 2
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.appLimitsTable} (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          package_name TEXT NOT NULL,
          app_name TEXT NOT NULL,
          app_icon BLOB,
          daily_limit_minutes INTEGER NOT NULL,
          used_today_minutes INTEGER DEFAULT 0,
          is_enabled INTEGER DEFAULT 1,
          last_reset_date TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id),
          UNIQUE (user_id, package_name)
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_app_limits_user_id ON ${DatabaseConstants.appLimitsTable} (user_id)',
      );
    }
    
    // Version 3: No schema changes, just force database refresh
    // This handles the case where version 2 was added but upgrade didn't run
    if (oldVersion < 3) {
      // Check if app_limits table exists
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConstants.appLimitsTable}'",
      );
      
      if (result.isEmpty) {
        // Create app_limits table if it doesn't exist
        await db.execute('''
          CREATE TABLE ${DatabaseConstants.appLimitsTable} (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            package_name TEXT NOT NULL,
            app_name TEXT NOT NULL,
            app_icon BLOB,
            daily_limit_minutes INTEGER NOT NULL,
            used_today_minutes INTEGER DEFAULT 0,
            is_enabled INTEGER DEFAULT 1,
            last_reset_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable} (id),
            UNIQUE (user_id, package_name)
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_app_limits_user_id ON ${DatabaseConstants.appLimitsTable} (user_id)',
        );
      }
    }
  }

  // ==================== User Operations ====================

  /// Insert a new user
  Future<bool> insertUser(UserModel user, String passwordHash) async {
    try {
      final db = await database;
      final userData = user.toMap();
      userData['password_hash'] = passwordHash;
      await db.insert(DatabaseConstants.usersTable, userData);
      return true;
    } catch (e) {
      print('Error inserting user: $e');
      return false;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Get password hash for user
  Future<String?> getPasswordHash(String email) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.usersTable,
      columns: ['password_hash'],
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) return null;
    return results.first['password_hash'] as String?;
  }

  /// Update user
  Future<bool> updateUser(UserModel user) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.usersTable,
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Update face registration status
  Future<bool> updateFaceRegistrationStatus(String userId, bool isRegistered) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.usersTable,
        {'is_face_registered': isRegistered ? 1 : 0},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Error updating face registration status: $e');
      return false;
    }
  }

  // ==================== Attendance Operations ====================

  /// Insert attendance record
  Future<bool> insertAttendance(AttendanceModel attendance) async {
    try {
      final db = await database;
      await db.insert(DatabaseConstants.attendanceTable, attendance.toMap());
      return true;
    } catch (e) {
      print('Error inserting attendance: $e');
      return false;
    }
  }

  /// Get attendance by user and date
  Future<List<AttendanceModel>> getAttendanceByUserAndDate(
    String userId,
    DateTime date,
  ) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await db.query(
      DatabaseConstants.attendanceTable,
      where: 'user_id = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );

    return results.map((row) => AttendanceModel.fromMap(row)).toList();
  }

  /// Get attendance history for user
  Future<List<AttendanceModel>> getAttendanceHistory(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.attendanceTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) => AttendanceModel.fromMap(row)).toList();
  }

  /// Get attendance for date range
  Future<List<AttendanceModel>> getAttendanceForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.attendanceTable,
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );

    return results.map((row) => AttendanceModel.fromMap(row)).toList();
  }

  /// Get today's check-in for user
  Future<AttendanceModel?> getTodayCheckIn(String userId) async {
    final today = DateTime.now();
    final records = await getAttendanceByUserAndDate(userId, today);
    
    for (final record in records) {
      if (record.type == AttendanceType.checkIn) {
        return record;
      }
    }
    return null;
  }

  /// Get today's check-out for user
  Future<AttendanceModel?> getTodayCheckOut(String userId) async {
    final today = DateTime.now();
    final records = await getAttendanceByUserAndDate(userId, today);
    
    for (final record in records) {
      if (record.type == AttendanceType.checkOut) {
        return record;
      }
    }
    return null;
  }

  // ==================== Face Data Operations ====================

  /// Insert face data
  Future<bool> insertFaceData(FaceDataModel faceData) async {
    try {
      final db = await database;
      await db.insert(DatabaseConstants.faceDataTable, faceData.toMap());
      return true;
    } catch (e) {
      print('Error inserting face data: $e');
      return false;
    }
  }

  /// Get face data for user
  Future<List<FaceDataModel>> getFaceDataForUser(String userId) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.faceDataTable,
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results.map((row) => FaceDataModel.fromMap(row)).toList();
  }

  /// Get all active face data
  Future<List<FaceDataModel>> getAllActiveFaceData() async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.faceDataTable,
      where: 'is_active = 1',
    );

    return results.map((row) => FaceDataModel.fromMap(row)).toList();
  }

  /// Delete face data for user
  Future<bool> deleteFaceDataForUser(String userId) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.faceDataTable,
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Error deleting face data: $e');
      return false;
    }
  }

  // ==================== Statistics ====================

  /// Get attendance statistics for user
  Future<Map<String, int>> getAttendanceStats(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final records = await getAttendanceForDateRange(userId, startDate, endDate);
    
    int present = 0;
    int late = 0;
    int absent = 0;
    int halfDay = 0;

    // Count unique days
    final checkedDays = <String>{};
    
    for (final record in records) {
      if (record.type == AttendanceType.checkIn) {
        final dayKey = '${record.timestamp.year}-${record.timestamp.month}-${record.timestamp.day}';
        if (!checkedDays.contains(dayKey)) {
          checkedDays.add(dayKey);
          switch (record.status) {
            case AttendanceStatus.present:
              present++;
              break;
            case AttendanceStatus.late:
              late++;
              break;
            case AttendanceStatus.absent:
              absent++;
              break;
            case AttendanceStatus.halfDay:
              halfDay++;
              break;
          }
        }
      }
    }

    return {
      'present': present,
      'late': late,
      'absent': absent,
      'halfDay': halfDay,
      'total': checkedDays.length,
    };
  }

  // ==================== App Limits Operations ====================

  /// Insert app limit
  Future<bool> insertAppLimit(String userId, AppLimitModel appLimit) async {
    try {
      final db = await database;
      final data = appLimit.toMap();
      data['user_id'] = userId;
      data['packageName'] = appLimit.packageName;
      data['appName'] = appLimit.appName;
      data['appIcon'] = appLimit.appIcon;
      data['dailyLimitMinutes'] = appLimit.dailyLimitMinutes;
      data['usedTodayMinutes'] = appLimit.usedTodayMinutes;
      data['isEnabled'] = appLimit.isEnabled ? 1 : 0;
      data['lastResetDate'] = appLimit.lastResetDate?.toIso8601String();
      data['createdAt'] = appLimit.createdAt.toIso8601String();
      data['updatedAt'] = appLimit.updatedAt.toIso8601String();
      
      await db.insert(
        DatabaseConstants.appLimitsTable,
        {
          'id': appLimit.id,
          'user_id': userId,
          'package_name': appLimit.packageName,
          'app_name': appLimit.appName,
          'app_icon': appLimit.appIcon,
          'daily_limit_minutes': appLimit.dailyLimitMinutes,
          'used_today_minutes': appLimit.usedTodayMinutes,
          'is_enabled': appLimit.isEnabled ? 1 : 0,
          'last_reset_date': appLimit.lastResetDate?.toIso8601String(),
          'created_at': appLimit.createdAt.toIso8601String(),
          'updated_at': appLimit.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      print('Error inserting app limit: $e');
      return false;
    }
  }

  /// Get all app limits for user
  Future<List<AppLimitModel>> getAppLimits(String userId) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.appLimitsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'app_name ASC',
    );
    
    return results.map((map) => AppLimitModel(
      id: map['id'] as String,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      appIcon: map['app_icon'] as Uint8List?,
      dailyLimitMinutes: map['daily_limit_minutes'] as int,
      usedTodayMinutes: map['used_today_minutes'] as int? ?? 0,
      isEnabled: map['is_enabled'] == 1,
      lastResetDate: map['last_reset_date'] != null
          ? DateTime.parse(map['last_reset_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  /// Get app limit by package name
  Future<AppLimitModel?> getAppLimitByPackage(String userId, String packageName) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.appLimitsTable,
      where: 'user_id = ? AND package_name = ?',
      whereArgs: [userId, packageName],
    );
    
    if (results.isEmpty) return null;
    
    final map = results.first;
    return AppLimitModel(
      id: map['id'] as String,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      appIcon: map['app_icon'] as Uint8List?,
      dailyLimitMinutes: map['daily_limit_minutes'] as int,
      usedTodayMinutes: map['used_today_minutes'] as int? ?? 0,
      isEnabled: map['is_enabled'] == 1,
      lastResetDate: map['last_reset_date'] != null
          ? DateTime.parse(map['last_reset_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Update app limit
  Future<bool> updateAppLimit(AppLimitModel appLimit) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.appLimitsTable,
        {
          'daily_limit_minutes': appLimit.dailyLimitMinutes,
          'used_today_minutes': appLimit.usedTodayMinutes,
          'is_enabled': appLimit.isEnabled ? 1 : 0,
          'last_reset_date': appLimit.lastResetDate?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [appLimit.id],
      );
      return true;
    } catch (e) {
      print('Error updating app limit: $e');
      return false;
    }
  }

  /// Update used time for an app
  Future<bool> updateUsedTime(String appLimitId, int usedMinutes) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.appLimitsTable,
        {
          'used_today_minutes': usedMinutes,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [appLimitId],
      );
      return true;
    } catch (e) {
      print('Error updating used time: $e');
      return false;
    }
  }

  /// Reset all daily usage counters for user
  Future<bool> resetDailyUsage(String userId) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.appLimitsTable,
        {
          'used_today_minutes': 0,
          'last_reset_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Error resetting daily usage: $e');
      return false;
    }
  }

  /// Delete app limit
  Future<bool> deleteAppLimit(String appLimitId) async {
    try {
      final db = await database;
      await db.delete(
        DatabaseConstants.appLimitsTable,
        where: 'id = ?',
        whereArgs: [appLimitId],
      );
      return true;
    } catch (e) {
      print('Error deleting app limit: $e');
      return false;
    }
  }

  /// Toggle app limit enabled/disabled
  Future<bool> toggleAppLimit(String appLimitId, bool isEnabled) async {
    try {
      final db = await database;
      await db.update(
        DatabaseConstants.appLimitsTable,
        {
          'is_enabled': isEnabled ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [appLimitId],
      );
      return true;
    } catch (e) {
      print('Error toggling app limit: $e');
      return false;
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

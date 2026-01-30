/// App-wide constants for FaceGuard application
library;

/// Application metadata
class AppMetadata {
  static const String appName = 'FaceGuard';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'App Usage Timer with Face Recognition';
  static const String developerName = 'FaceGuard Team';
}

/// Route names for navigation
class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String faceRegistration = '/face-registration';
  static const String home = '/home';
  static const String markAttendance = '/mark-attendance';
  static const String attendanceHistory = '/attendance-history';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String appSelection = '/app-selection';
  static const String appLimits = '/app-limits';
  static const String pinSetup = '/pin-setup';
  static const String pinLogin = '/pin-login';
}

/// Storage keys for SharedPreferences
class StorageKeys {
  static const String isFirstLaunch = 'is_first_launch';
  static const String isLoggedIn = 'is_logged_in';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String faceRegistered = 'face_registered';
  static const String themeMode = 'theme_mode';
  static const String userPin = 'user_pin';
  static const String pinEnabled = 'pin_enabled';
  static const String lastUsageReset = 'last_usage_reset';
}

/// Database constants
class DatabaseConstants {
  static const String databaseName = 'faceguard.db';
  static const int databaseVersion = 3;
  
  // Table names
  static const String usersTable = 'users';
  static const String attendanceTable = 'attendance';
  static const String faceDataTable = 'face_data';
  static const String appLimitsTable = 'app_limits';
}

/// Face detection constants
class FaceDetectionConstants {
  static const double minFaceSize = 0.15; // Minimum face size relative to image
  static const double faceMatchThreshold = 0.6; // Similarity threshold for face matching
  static const int maxFaceImages = 5; // Maximum face images to store per user
  static const int faceImageSize = 112; // Size for face image processing
}

/// Animation durations
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration splash = Duration(seconds: 3);
}

/// Validation patterns
class ValidationPatterns {
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phone = RegExp(r'^\+?[\d\s-]{10,}$');
  static final RegExp password = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
}

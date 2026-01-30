import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/face_detection_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/face_registration_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/mark_attendance_screen.dart';
import 'screens/attendance/attendance_history_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/apps/app_selection_screen.dart';
import 'screens/apps/app_limits_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.database;
  
  final authService = AuthService();
  await authService.initialize();
  
  final faceDetectionService = FaceDetectionService();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<FaceDetectionService>.value(value: faceDetectionService),
      ],
      child: const FaceGuardApp(),
    ),
  );
}

class FaceGuardApp extends StatelessWidget {
  const FaceGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: Routes.splash,
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(const SplashScreen(), settings);
      
      case Routes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      
      case Routes.login:
        return _buildRoute(const LoginScreen(), settings);
      
      case Routes.register:
        return _buildRoute(const RegisterScreen(), settings);
      
      case Routes.faceRegistration:
        return _buildRoute(const FaceRegistrationScreen(), settings);
      
      case Routes.home:
        return _buildRoute(const HomeScreen(), settings);
      
      case Routes.markAttendance:
        return _buildRoute(const MarkAttendanceScreen(), settings);
      
      case Routes.attendanceHistory:
        return _buildRoute(const AttendanceHistoryScreen(), settings);
      
      case Routes.profile:
        return _buildRoute(const ProfileScreen(), settings);
      
      case Routes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      
      case Routes.appSelection:
        return _buildRoute(const AppSelectionScreen(), settings);
      
      case Routes.appLimits:
        return _buildRoute(const AppLimitsScreen(), settings);
      
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}

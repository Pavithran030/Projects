import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'database_service.dart';

/// Simple hash function using dart:convert
String _simpleHash(String input) {
  final bytes = utf8.encode(input);
  // Use a simple base64 encoding as a placeholder
  // In production, use a proper crypto package
  return base64Encode(bytes);
}

/// Authentication service for user management
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _databaseService = DatabaseService();
  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Initialize auth service and check for existing session
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
      
      if (isLoggedIn) {
        final userId = prefs.getString(StorageKeys.userId);
        if (userId != null) {
          _currentUser = await _databaseService.getUserById(userId);
          return _currentUser != null;
        }
      }
      return false;
    } catch (e) {
      print('Error initializing auth service: $e');
      return false;
    }
  }

  /// Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(StorageKeys.isFirstLaunch) ?? true;
    if (isFirst) {
      await prefs.setBool(StorageKeys.isFirstLaunch, false);
    }
    return isFirst;
  }

  /// Register a new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? department,
    String? designation,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _databaseService.getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: 'An account with this email already exists',
        );
      }

      // Validate email
      if (!ValidationPatterns.email.hasMatch(email)) {
        return AuthResult(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

      // Validate password
      if (password.length < 8) {
        return AuthResult(
          success: false,
          message: 'Password must be at least 8 characters long',
        );
      }

      // Create user
      final userId = const Uuid().v4();
      final user = UserModel(
        id: userId,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone?.trim(),
        department: department?.trim(),
        designation: designation?.trim(),
        createdAt: DateTime.now(),
      );

      // Hash password
      final passwordHash = _hashPassword(password);

      // Save to database
      final success = await _databaseService.insertUser(user, passwordHash);
      if (!success) {
        return AuthResult(
          success: false,
          message: 'Failed to create account. Please try again.',
        );
      }

      // Auto login after registration
      _currentUser = user;
      await _saveSession(user);

      return AuthResult(
        success: true,
        message: 'Account created successfully',
        user: user,
      );
    } catch (e) {
      print('Error during registration: $e');
      return AuthResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Get user by email
      final user = await _databaseService.getUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      // Verify password
      final storedHash = await _databaseService.getPasswordHash(email.trim().toLowerCase());
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        return AuthResult(
          success: false,
          message: 'Incorrect password',
        );
      }

      // Save session
      _currentUser = user;
      await _saveSession(user);

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: user,
      );
    } catch (e) {
      print('Error during login: $e');
      return AuthResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.isLoggedIn);
      await prefs.remove(StorageKeys.userId);
      await prefs.remove(StorageKeys.userName);
      await prefs.remove(StorageKeys.userEmail);
      _currentUser = null;
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? designation,
    String? profileImagePath,
  }) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        message: 'No user logged in',
      );
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        department: department ?? _currentUser!.department,
        designation: designation ?? _currentUser!.designation,
        profileImagePath: profileImagePath ?? _currentUser!.profileImagePath,
        updatedAt: DateTime.now(),
      );

      final success = await _databaseService.updateUser(updatedUser);
      if (!success) {
        return AuthResult(
          success: false,
          message: 'Failed to update profile',
        );
      }

      _currentUser = updatedUser;
      await _saveSession(updatedUser);

      return AuthResult(
        success: true,
        message: 'Profile updated successfully',
        user: updatedUser,
      );
    } catch (e) {
      print('Error updating profile: $e');
      return AuthResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Update face registration status
  Future<bool> updateFaceRegistrationStatus(bool isRegistered) async {
    if (_currentUser == null) return false;

    try {
      final success = await _databaseService.updateFaceRegistrationStatus(
        _currentUser!.id,
        isRegistered,
      );

      if (success) {
        _currentUser = _currentUser!.copyWith(isFaceRegistered: isRegistered);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.faceRegistered, isRegistered);
      }

      return success;
    } catch (e) {
      print('Error updating face registration status: $e');
      return false;
    }
  }

  /// Check if face is registered for current user
  Future<bool> isFaceRegistered() async {
    if (_currentUser == null) return false;
    return _currentUser!.isFaceRegistered;
  }

  /// Save user session
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isLoggedIn, true);
    await prefs.setString(StorageKeys.userId, user.id);
    await prefs.setString(StorageKeys.userName, user.name);
    await prefs.setString(StorageKeys.userEmail, user.email);
    await prefs.setBool(StorageKeys.faceRegistered, user.isFaceRegistered);
  }

  /// Hash password using simple encoding
  String _hashPassword(String password) {
    return _simpleHash(password + 'faceguard_salt');
  }
}

/// Result class for auth operations
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../services/camera_service.dart';
import '../../services/face_detection_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/attendance_model.dart';
import '../../models/face_data_model.dart';

/// Screen for marking attendance using face recognition
class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _isVerifying = false;
  String _statusMessage = 'Initializing camera...';
  AttendanceType _attendanceType = AttendanceType.checkIn;
  bool _hasCheckedInToday = false;
  bool _hasCheckedOutToday = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _faceDetectionService.initialize();
      final success = await _cameraService.startCamera();

      if (!success) {
        setState(() {
          _statusMessage = 'Camera permission required';
          _isInitializing = false;
        });
        return;
      }

      // Check today's attendance status
      await _checkTodayAttendance();

      setState(() {
        _isInitializing = false;
        _statusMessage = 'Position your face and tap to verify';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _checkTodayAttendance() async {
    final userId = _authService.currentUser?.id ?? '';
    final checkIn = await _databaseService.getTodayCheckIn(userId);
    final checkOut = await _databaseService.getTodayCheckOut(userId);

    setState(() {
      _hasCheckedInToday = checkIn != null;
      _hasCheckedOutToday = checkOut != null;
      
      if (!_hasCheckedInToday) {
        _attendanceType = AttendanceType.checkIn;
      } else if (!_hasCheckedOutToday) {
        _attendanceType = AttendanceType.checkOut;
      }
    });
  }

  Future<void> _captureAndVerify() async {
    if (_isProcessing || _isVerifying) return;

    // Check if already completed for the day
    if (_hasCheckedInToday && _hasCheckedOutToday) {
      _showMessage('You have already completed attendance for today.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing...';
    });

    try {
      final file = await _cameraService.takePicture();
      if (file == null) {
        setState(() {
          _statusMessage = 'Failed to capture. Try again.';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _isVerifying = true;
        _statusMessage = 'Verifying face...';
      });

      // Detect face in captured image
      final faces = await _faceDetectionService.detectFacesFromFile(file.path);

      if (faces.isEmpty) {
        setState(() {
          _statusMessage = 'No face detected. Please try again.';
          _isProcessing = false;
          _isVerifying = false;
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _statusMessage = 'Multiple faces detected. Ensure only your face is visible.';
          _isProcessing = false;
          _isVerifying = false;
        });
        return;
      }

      final face = faces.first;

      // Check face quality
      if (!_faceDetectionService.isValidFace(face)) {
        setState(() {
          _statusMessage = 'Please look straight at the camera.';
          _isProcessing = false;
          _isVerifying = false;
        });
        return;
      }

      // Generate embedding for captured face
      final capturedEmbedding = _faceDetectionService.generateFaceEmbedding(face);

      // Get stored face data for current user
      final userId = _authService.currentUser?.id ?? '';
      final storedFaceData = await _databaseService.getFaceDataForUser(userId);

      if (storedFaceData.isEmpty) {
        setState(() {
          _statusMessage = 'Face not registered. Please register first.';
          _isProcessing = false;
          _isVerifying = false;
        });
        
        // Prompt to register face
        _showFaceRegistrationPrompt();
        return;
      }

      // Verify against stored face data
      bool isVerified = false;
      double bestScore = 0.0;

      for (final faceData in storedFaceData) {
        final similarity = _faceDetectionService.compareFaces(
          capturedEmbedding,
          faceData.embedding,
        );
        if (similarity > bestScore) {
          bestScore = similarity;
        }
        if (similarity >= FaceDetectionConstants.faceMatchThreshold) {
          isVerified = true;
          break;
        }
      }

      if (!isVerified) {
        setState(() {
          _statusMessage = 'Face verification failed. Please try again.';
          _isProcessing = false;
          _isVerifying = false;
        });
        return;
      }

      // Face verified - mark attendance
      await _markAttendance(file.path, bestScore);

    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isProcessing = false;
        _isVerifying = false;
      });
    }
  }

  Future<void> _markAttendance(String imagePath, double confidenceScore) async {
    final userId = _authService.currentUser?.id ?? '';
    final now = DateTime.now();

    // Determine attendance status (late if after 9:00 AM for check-in)
    AttendanceStatus status = AttendanceStatus.present;
    if (_attendanceType == AttendanceType.checkIn) {
      final nineAM = DateTime(now.year, now.month, now.day, 9, 0);
      if (now.isAfter(nineAM)) {
        status = AttendanceStatus.late;
      }
    }

    final attendance = AttendanceModel(
      id: const Uuid().v4(),
      oderId: userId,
      type: _attendanceType,
      status: status,
      timestamp: now,
      faceImagePath: imagePath,
      confidenceScore: confidenceScore,
    );

    final success = await _databaseService.insertAttendance(attendance);

    if (success) {
      setState(() {
        _isProcessing = false;
        _isVerifying = false;
      });
      
      _showSuccessDialog(attendance);
    } else {
      setState(() {
        _statusMessage = 'Failed to save attendance. Please try again.';
        _isProcessing = false;
        _isVerifying = false;
      });
    }
  }

  void _showSuccessDialog(AttendanceModel attendance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: AppColors.success,
              ),
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              attendance.isCheckIn ? 'Checked In!' : 'Checked Out!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              attendance.formattedTime,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              attendance.formattedDate,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey400,
                  ),
            ),
            if (attendance.status == AttendanceStatus.late) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Late Arrival',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFaceRegistrationPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Face Not Registered',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
              ),
        ),
        content: Text(
          'You need to register your face before marking attendance. Would you like to register now?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey400,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, Routes.faceRegistration);
            },
            child: const Text('Register Face'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.stopCamera();
    super.dispose();
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
                        'Mark Attendance',
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

              // Attendance type toggle
              if (!_hasCheckedInToday || !_hasCheckedOutToday)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          'Check In',
                          Icons.login_rounded,
                          AttendanceType.checkIn,
                          _hasCheckedInToday,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTypeButton(
                          'Check Out',
                          Icons.logout_rounded,
                          AttendanceType.checkOut,
                          _hasCheckedOutToday || !_hasCheckedInToday,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms),

              const SizedBox(height: 30),

              // Camera preview
              Expanded(
                child: _isInitializing
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _cameraService.controller == null ||
                            !_cameraService.controller!.value.isInitialized
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 64,
                                  color: AppColors.grey500,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _statusMessage,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: AppColors.grey400),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _initialize,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              // Camera preview
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SizedBox(
                                  width: 300,
                                  height: 400,
                                  child: CameraPreview(_cameraService.controller!),
                                ),
                              ),

                              // Face guide overlay
                              Container(
                                width: 300,
                                height: 400,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isVerifying
                                        ? AppColors.success
                                        : AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                              ),

                              // Face oval guide
                              Container(
                                width: 200,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: _isVerifying
                                        ? AppColors.success.withValues(alpha: 0.7)
                                        : AppColors.primary.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                              )
                                  .animate(
                                    onPlay: (controller) => controller.repeat(),
                                  )
                                  .shimmer(
                                    duration: 2.seconds,
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),

                              // Processing overlay
                              if (_isProcessing)
                                Container(
                                  width: 300,
                                  height: 400,
                                  decoration: BoxDecoration(
                                    color: AppColors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _isVerifying ? 'Verifying...' : 'Processing...',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
              ),

              // Status and capture button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.white,
                          ),
                    )
                        .animate(key: ValueKey(_statusMessage))
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Already completed message
                    if (_hasCheckedInToday && _hasCheckedOutToday)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Attendance completed for today!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.success,
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Capture button
                      GestureDetector(
                        onTap: (_isInitializing || _isProcessing)
                            ? null
                            : _captureAndVerify,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isInitializing || _isProcessing)
                                ? AppColors.grey600
                                : _attendanceType == AttendanceType.checkIn
                                    ? AppColors.success
                                    : AppColors.warning,
                            boxShadow: [
                              BoxShadow(
                                color: (_attendanceType == AttendanceType.checkIn
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isProcessing
                                ? Icons.hourglass_top
                                : _attendanceType == AttendanceType.checkIn
                                    ? Icons.login_rounded
                                    : Icons.logout_rounded,
                            size: 36,
                            color: AppColors.white,
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 300.ms),

                    const SizedBox(height: 16),

                    Text(
                      _hasCheckedInToday && _hasCheckedOutToday
                          ? 'See you tomorrow!'
                          : 'Tap to ${_attendanceType == AttendanceType.checkIn ? 'Check In' : 'Check Out'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    AttendanceType type,
    bool isDisabled,
  ) {
    final isSelected = _attendanceType == type;
    final color = type == AttendanceType.checkIn ? AppColors.success : AppColors.warning;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _attendanceType = type;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected && !isDisabled
              ? color.withValues(alpha: 0.2)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected && !isDisabled ? color : AppColors.grey700,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDisabled ? Icons.check_circle : icon,
              color: isDisabled
                  ? AppColors.grey500
                  : isSelected
                      ? color
                      : AppColors.grey400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? AppColors.grey500
                    : isSelected
                        ? color
                        : AppColors.grey400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
import '../../models/face_data_model.dart';

/// Screen for registering user's face for authentication
class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _faceDetected = false;
  bool _isCapturing = false;
  int _capturedImages = 0;
  final int _requiredImages = 3;
  String _statusMessage = 'Initializing camera...';
  final List<String> _capturedPaths = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _faceDetectionService.initialize();
      final success = await _cameraService.startCamera();
      
      if (!success) {
        setState(() {
          _statusMessage = 'Failed to initialize camera. Please grant camera permission.';
          _isInitializing = false;
        });
        return;
      }

      setState(() {
        _isInitializing = false;
        _statusMessage = 'Position your face in the circle';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = 'Capturing...';
    });

    try {
      final file = await _cameraService.takePicture();
      if (file == null) {
        setState(() {
          _statusMessage = 'Failed to capture image. Try again.';
          _isCapturing = false;
        });
        return;
      }

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Processing face...';
      });

      // Detect faces in captured image
      final faces = await _faceDetectionService.detectFacesFromFile(file.path);

      if (faces.isEmpty) {
        setState(() {
          _statusMessage = 'No face detected. Please try again.';
          _isProcessing = false;
          _isCapturing = false;
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _statusMessage = 'Multiple faces detected. Please ensure only your face is visible.';
          _isProcessing = false;
          _isCapturing = false;
        });
        return;
      }

      final face = faces.first;

      // Check face quality
      if (!_faceDetectionService.isValidFace(face)) {
        setState(() {
          _statusMessage = 'Please look straight at the camera with eyes open.';
          _isProcessing = false;
          _isCapturing = false;
        });
        return;
      }

      // Extract and save face image
      final faceImagePath = await _faceDetectionService.extractFaceImage(file.path, face);
      
      if (faceImagePath != null) {
        _capturedPaths.add(faceImagePath);
      }

      // Generate face embedding
      final embedding = _faceDetectionService.generateFaceEmbedding(face);

      // Save face data
      final userId = _authService.currentUser?.id ?? '';
      final faceData = FaceDataModel(
        id: const Uuid().v4(),
        userId: userId,
        embedding: embedding,
        imagePath: faceImagePath,
        createdAt: DateTime.now(),
      );

      await _databaseService.insertFaceData(faceData);

      setState(() {
        _capturedImages++;
        _isProcessing = false;
        _isCapturing = false;
        _faceDetected = true;

        if (_capturedImages >= _requiredImages) {
          _statusMessage = 'Face registration complete!';
        } else {
          _statusMessage = 'Great! ${_requiredImages - _capturedImages} more capture(s) needed.';
        }
      });

      // If all images captured, proceed to complete registration
      if (_capturedImages >= _requiredImages) {
        await _completeRegistration();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error processing image. Please try again.';
        _isProcessing = false;
        _isCapturing = false;
      });
    }
  }

  Future<void> _completeRegistration() async {
    await _authService.updateFaceRegistrationStatus(true);
    
    if (!mounted) return;

    // Show success dialog
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
              'Face Registered!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your face has been successfully registered. You can now use face recognition to mark attendance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey400,
                  ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, Routes.home);
              },
              child: const Text('Continue to Home'),
            ),
          ),
        ],
      ),
    );
  }

  void _skipRegistration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Skip Face Registration?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
              ),
        ),
        content: Text(
          'You won\'t be able to mark attendance using face recognition until you register your face.',
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
              Navigator.pushReplacementNamed(context, Routes.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Skip Anyway'),
          ),
        ],
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
                      onPressed: _skipRegistration,
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Face Registration',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_requiredImages, (index) {
                        final isComplete = index < _capturedImages;
                        final isCurrent = index == _capturedImages;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isComplete
                                ? AppColors.success
                                : isCurrent
                                    ? AppColors.primary
                                    : AppColors.grey700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_capturedImages / $_requiredImages captures',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey400,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                                    color: _faceDetected
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
                                    color: _faceDetected
                                        ? AppColors.success.withValues(alpha: 0.7)
                                        : AppColors.primary.withValues(alpha: 0.5),
                                    width: 2,
                                    strokeAlign: BorderSide.strokeAlignOutside,
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
                                    color: AppColors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),

              // Status message
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _capturedImages >= _requiredImages
                                ? AppColors.success
                                : AppColors.white,
                          ),
                    )
                        .animate(key: ValueKey(_statusMessage))
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Capture button
                    if (_capturedImages < _requiredImages)
                      GestureDetector(
                        onTap: (_isInitializing || _isProcessing || _isCapturing)
                            ? null
                            : _captureAndProcess,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isInitializing || _isProcessing || _isCapturing)
                                ? AppColors.grey600
                                : AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isCapturing ? Icons.hourglass_top : Icons.camera_alt,
                            size: 36,
                            color: AppColors.white,
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 300.ms),

                    const SizedBox(height: 16),

                    // Skip button
                    TextButton(
                      onPressed: _skipRegistration,
                      child: Text(
                        'Skip for now',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey400,
                            ),
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
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing camera operations
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  int _currentCameraIndex = 1; // Default to front camera

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription>? get cameras => _cameras;

  /// Initialize cameras
  Future<bool> initialize() async {
    try {
      // Check camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Find front camera
      for (int i = 0; i < _cameras!.length; i++) {
        if (_cameras![i].lensDirection == CameraLensDirection.front) {
          _currentCameraIndex = i;
          break;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error initializing camera service: $e');
      return false;
    }
  }

  /// Start camera with specified resolution
  Future<bool> startCamera({
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      if (_cameras == null || _cameras!.isEmpty) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      // Dispose existing controller if any
      await stopCamera();

      _controller = CameraController(
        _cameras![_currentCameraIndex],
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;

      return true;
    } catch (e) {
      debugPrint('Error starting camera: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Stop camera and release resources
  Future<void> stopCamera() async {
    if (_controller != null) {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return false;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    return await startCamera();
  }

  /// Set to front camera
  Future<bool> useFrontCamera() async {
    if (_cameras == null) return false;

    for (int i = 0; i < _cameras!.length; i++) {
      if (_cameras![i].lensDirection == CameraLensDirection.front) {
        _currentCameraIndex = i;
        return await startCamera();
      }
    }
    return false;
  }

  /// Set to back camera
  Future<bool> useBackCamera() async {
    if (_cameras == null) return false;

    for (int i = 0; i < _cameras!.length; i++) {
      if (_cameras![i].lensDirection == CameraLensDirection.back) {
        _currentCameraIndex = i;
        return await startCamera();
      }
    }
    return false;
  }

  /// Take a picture
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile file = await _controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  /// Start image stream for real-time processing
  Future<void> startImageStream(
    void Function(CameraImage image) onImage,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isStreamingImages) {
      return;
    }

    await _controller!.startImageStream(onImage);
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setFlashMode(mode);
    }
  }

  /// Get current camera description
  CameraDescription? get currentCamera {
    if (_cameras == null || _cameras!.isEmpty) return null;
    return _cameras![_currentCameraIndex];
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await stopCamera();
    _cameras = null;
  }
}

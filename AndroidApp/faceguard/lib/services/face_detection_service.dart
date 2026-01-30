import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

/// Service for face detection and processing using Google ML Kit
class FaceDetectionService {
  static final FaceDetectionService _instance = FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;
  FaceDetectionService._internal();

  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  /// Initialize the face detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      minFaceSize: FaceDetectionConstants.minFaceSize,
      performanceMode: FaceDetectorMode.accurate,
    );

    _faceDetector = FaceDetector(options: options);
    _isInitialized = true;
  }

  /// Detect faces in an image file
  Future<List<Face>> detectFacesFromFile(String imagePath) async {
    if (!_isInitialized) await initialize();

    final inputImage = InputImage.fromFilePath(imagePath);
    return await _faceDetector.processImage(inputImage);
  }

  /// Detect faces from camera image
  Future<List<Face>> detectFacesFromCamera(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (!_isInitialized) await initialize();

    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null) return [];

    return await _faceDetector.processImage(inputImage);
  }

  /// Convert CameraImage to InputImage for processing
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation = _rotationIntToImageRotation(camera.sensorOrientation);

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Convert sensor orientation to InputImageRotation
  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Check if a valid face is detected
  bool isValidFace(Face face) {
    // Check if face is looking straight
    final headEulerAngleX = face.headEulerAngleX ?? 0;
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    // Face should be relatively straight
    if (headEulerAngleX.abs() > 20 ||
        headEulerAngleY.abs() > 20 ||
        headEulerAngleZ.abs() > 20) {
      return false;
    }

    // Check if eyes are open (if classification is available)
    final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;

    if (leftEyeOpenProbability < 0.5 || rightEyeOpenProbability < 0.5) {
      return false;
    }

    return true;
  }

  /// Get face quality score (0.0 to 1.0)
  double getFaceQualityScore(Face face) {
    double score = 1.0;

    // Deduct for head tilt
    final headEulerAngleX = (face.headEulerAngleX ?? 0).abs();
    final headEulerAngleY = (face.headEulerAngleY ?? 0).abs();
    final headEulerAngleZ = (face.headEulerAngleZ ?? 0).abs();

    score -= (headEulerAngleX / 90) * 0.3;
    score -= (headEulerAngleY / 90) * 0.3;
    score -= (headEulerAngleZ / 90) * 0.2;

    // Bonus for open eyes
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;
    score += (leftEyeOpen + rightEyeOpen) / 2 * 0.1;

    // Bonus for smiling (indicates good lighting/visibility)
    final smilingProbability = face.smilingProbability ?? 0.0;
    score += smilingProbability * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Extract face region from image file
  Future<String?> extractFaceImage(
    String imagePath,
    Face face,
  ) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      final boundingBox = face.boundingBox;
      
      // Add padding around the face
      final padding = boundingBox.width * 0.2;
      final left = (boundingBox.left - padding).clamp(0.0, originalImage.width.toDouble());
      final top = (boundingBox.top - padding).clamp(0.0, originalImage.height.toDouble());
      final right = (boundingBox.right + padding).clamp(0.0, originalImage.width.toDouble());
      final bottom = (boundingBox.bottom + padding).clamp(0.0, originalImage.height.toDouble());

      // Create a new image with just the face
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      final srcRect = ui.Rect.fromLTRB(left, top, right, bottom);
      final dstRect = ui.Rect.fromLTWH(0, 0, right - left, bottom - top);
      
      canvas.drawImageRect(originalImage, srcRect, dstRect, ui.Paint());
      
      final picture = recorder.endRecording();
      final faceImage = await picture.toImage(
        (right - left).toInt(),
        (bottom - top).toInt(),
      );
      
      final byteData = await faceImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Save the face image
      final directory = await getApplicationDocumentsDirectory();
      final facesDir = Directory('${directory.path}/faces');
      if (!await facesDir.exists()) {
        await facesDir.create(recursive: true);
      }

      final faceImagePath = '${facesDir.path}/${const Uuid().v4()}.png';
      final faceFile = File(faceImagePath);
      await faceFile.writeAsBytes(byteData.buffer.asUint8List());

      return faceImagePath;
    } catch (e) {
      print('Error extracting face image: $e');
      return null;
    }
  }

  /// Generate a simple face embedding (placeholder for actual implementation)
  /// In production, you would use a face recognition model like FaceNet
  List<double> generateFaceEmbedding(Face face) {
    // This is a simplified embedding based on face landmarks
    // In a real app, you would use a proper face recognition model
    final List<double> embedding = [];

    // Add landmark-based features
    final landmarks = face.landmarks;
    
    for (final type in FaceLandmarkType.values) {
      final landmark = landmarks[type];
      if (landmark != null) {
        embedding.add(landmark.position.x.toDouble());
        embedding.add(landmark.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
    }

    // Add contour-based features
    final contours = face.contours;
    for (final type in FaceContourType.values) {
      final contour = contours[type];
      if (contour != null && contour.points.isNotEmpty) {
        // Add first and last points of each contour
        embedding.add(contour.points.first.x.toDouble());
        embedding.add(contour.points.first.y.toDouble());
        embedding.add(contour.points.last.x.toDouble());
        embedding.add(contour.points.last.y.toDouble());
      } else {
        embedding.addAll([0.0, 0.0, 0.0, 0.0]);
      }
    }

    // Normalize the embedding
    return _normalizeEmbedding(embedding);
  }

  /// Normalize embedding vector
  List<double> _normalizeEmbedding(List<double> embedding) {
    double norm = 0.0;
    for (final value in embedding) {
      norm += value * value;
    }
    norm = _sqrt(norm);

    if (norm == 0.0) return embedding;

    return embedding.map((v) => v / norm).toList();
  }

  /// Helper function for square root
  double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  /// Compare two face embeddings
  double compareFaces(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      normA += embedding1[i] * embedding1[i];
      normB += embedding2[i] * embedding2[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (_sqrt(normA) * _sqrt(normB));
  }

  /// Check if two faces match
  bool doFacesMatch(List<double> embedding1, List<double> embedding2) {
    final similarity = compareFaces(embedding1, embedding2);
    return similarity >= FaceDetectionConstants.faceMatchThreshold;
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _faceDetector.close();
      _isInitialized = false;
    }
  }
}

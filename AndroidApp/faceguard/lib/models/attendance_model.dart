import 'dart:convert';

/// Attendance type enumeration
enum AttendanceType {
  checkIn,
  checkOut,
}

/// Attendance status enumeration
enum AttendanceStatus {
  present,
  late,
  absent,
  halfDay,
}

/// Attendance record model for FaceGuard application
class AttendanceModel {
  final String id;
  final String oderId;
  final AttendanceType type;
  final AttendanceStatus status;
  final DateTime timestamp;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? faceImagePath;
  final double? confidenceScore;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.oderId,
    required this.type,
    required this.status,
    required this.timestamp,
    this.location,
    this.latitude,
    this.longitude,
    this.faceImagePath,
    this.confidenceScore,
    this.notes,
  });

  /// Check if this is a check-in
  bool get isCheckIn => type == AttendanceType.checkIn;

  /// Check if this is a check-out
  bool get isCheckOut => type == AttendanceType.checkOut;

  /// Get formatted time string
  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get formatted date string
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]}, ${timestamp.year}';
  }

  /// Create a copy with modified fields
  AttendanceModel copyWith({
    String? id,
    String? userId,
    AttendanceType? type,
    AttendanceStatus? status,
    DateTime? timestamp,
    String? location,
    double? latitude,
    double? longitude,
    String? faceImagePath,
    double? confidenceScore,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      faceImagePath: faceImagePath ?? this.faceImagePath,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': oderId,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'face_image_path': faceImagePath,
      'confidence_score': confidenceScore,
      'notes': notes,
    };
  }

  /// Create from Map (database row)
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      oderId: map['user_id'] as String,
      type: AttendanceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AttendanceType.checkIn,
      ),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.present,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      faceImagePath: map['face_image_path'] as String?,
      confidenceScore: map['confidence_score'] as double?,
      notes: map['notes'] as String?,
    );
  }

  /// Convert to JSON string
  String toJson() => json.encode(toMap());

  /// Create from JSON string
  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AttendanceModel(id: $id, type: $type, status: $status, timestamp: $timestamp)';
  }
}

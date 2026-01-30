import 'dart:convert';
import 'dart:typed_data';

/// Face data model for storing face embeddings and metadata
class FaceDataModel {
  final String id;
  final String userId;
  final List<double> embedding;
  final String? imagePath;
  final DateTime createdAt;
  final bool isActive;

  FaceDataModel({
    required this.id,
    required this.userId,
    required this.embedding,
    this.imagePath,
    required this.createdAt,
    this.isActive = true,
  });

  /// Get embedding as Float32List for efficient processing
  Float32List get embeddingAsFloat32List => Float32List.fromList(embedding);

  /// Calculate cosine similarity with another face embedding
  double cosineSimilarity(List<double> otherEmbedding) {
    if (embedding.length != otherEmbedding.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < embedding.length; i++) {
      dotProduct += embedding[i] * otherEmbedding[i];
      normA += embedding[i] * embedding[i];
      normB += otherEmbedding[i] * otherEmbedding[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Helper function for square root
  static double sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  /// Create a copy with modified fields
  FaceDataModel copyWith({
    String? id,
    String? userId,
    List<double>? embedding,
    String? imagePath,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return FaceDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      embedding: embedding ?? this.embedding,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'embedding': json.encode(embedding),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Create from Map (database row)
  factory FaceDataModel.fromMap(Map<String, dynamic> map) {
    final embeddingData = map['embedding'];
    List<double> embeddingList;
    
    if (embeddingData is String) {
      embeddingList = (json.decode(embeddingData) as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
    } else if (embeddingData is List) {
      embeddingList = embeddingData.map((e) => (e as num).toDouble()).toList();
    } else {
      embeddingList = [];
    }

    return FaceDataModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      embedding: embeddingList,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  /// Convert to JSON string
  String toJson() => json.encode(toMap());

  /// Create from JSON string
  factory FaceDataModel.fromJson(String source) =>
      FaceDataModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FaceDataModel(id: $id, userId: $userId, embeddingLength: ${embedding.length})';
  }
}

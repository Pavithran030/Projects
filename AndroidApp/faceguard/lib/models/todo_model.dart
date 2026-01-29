/// Data model for a Todo item
/// Represents a single task with title and completion status
class Todo {
  /// Unique identifier for the todo item
  final String id;
  
  /// The task description
  String title;
  
  /// Whether the task is completed
  bool isCompleted;
  
  /// Timestamp when the todo was created
  final DateTime createdAt;

  Todo({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  /// Toggle completion status
  void toggleCompleted() {
    isCompleted = !isCompleted;
  }

  /// Create a copy of this todo with modified fields
  Todo copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

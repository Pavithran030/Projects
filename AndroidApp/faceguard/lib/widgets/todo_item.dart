import 'package:flutter/material.dart';
import '../models/todo_model.dart';

/// Individual todo item widget with animations and interactions
class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Animation<double> animation;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap with SizeTransition for smooth height animation when adding/removing
    return SizeTransition(
      sizeFactor: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1, 0), // Slide from right
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut)),
        ),
        child: FadeTransition(
          opacity: animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Dismissible(
              key: Key(todo.id),
              direction: DismissDirection.endToStart,
              background: _buildDismissBackground(),
              onDismissed: (_) => onDelete(),
              child: _buildTodoCard(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the swipe-to-delete background
  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.delete_sweep,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  /// Build the main todo card
  Widget _buildTodoCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? Colors.grey[100]
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: todo.isCompleted
              ? Colors.grey[300]!
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Animated checkbox
                _buildAnimatedCheckbox(context),
                const SizedBox(width: 12),
                // Task title
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: todo.isCompleted
                          ? Colors.grey[500]
                          : Theme.of(context).colorScheme.onSurface,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2,
                    ),
                    child: Text(
                      todo.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete task',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build animated checkbox with smooth transition
  Widget _buildAnimatedCheckbox(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: todo.isCompleted
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: todo.isCompleted
            ? const Icon(
                Icons.check,
                size: 18,
                color: Colors.white,
                key: ValueKey('checked'),
              )
            : const SizedBox.shrink(key: ValueKey('unchecked')),
      ),
    );
  }
}

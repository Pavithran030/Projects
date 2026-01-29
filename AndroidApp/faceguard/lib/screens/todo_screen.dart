import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../widgets/todo_item.dart';
import '../widgets/add_todo_dialog.dart';

/// Main screen displaying the todo list with animations
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  /// List of all todos (in-memory storage)
  final List<Todo> _todos = [];

  /// Global key for AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  /// Animation controller for page entrance
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade-in animation for the whole page
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start the entrance animation
    _fadeController.forward();

    // Add some sample todos for demonstration
    _addSampleTodos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Add sample todos on first load (optional - remove in production)
  void _addSampleTodos() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _addTodo('Welcome to your Todo List! 🎉');
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _addTodo('Swipe left to delete tasks');
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                _addTodo('Tap to mark as complete');
              }
            });
          }
        });
      }
    });
  }

  /// Add a new todo with animation
  void _addTodo(String title) {
    if (title.trim().isEmpty) return;

    final newTodo = Todo(title: title.trim());
    final index = 0; // Always insert at the top

    setState(() {
      _todos.insert(index, newTodo);
    });

    // Animate the insertion
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Toggle todo completion status
  void _toggleTodo(int index) {
    setState(() {
      _todos[index].toggleCompleted();
    });
  }

  /// Delete a todo with animation
  void _deleteTodo(int index) {
    final removedTodo = _todos[index];

    setState(() {
      _todos.removeAt(index);
    });

    // Animate the removal
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => TodoItem(
        todo: removedTodo,
        animation: animation,
        onToggle: () {},
        onDelete: () {},
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Show the add todo dialog
  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onAdd: _addTodo,
      ),
    );
  }

  /// Calculate completion statistics
  Map<String, int> _getStats() {
    final completed = _todos.where((todo) => todo.isCompleted).length;
    final total = _todos.length;
    return {'completed': completed, 'total': total};
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(stats),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _todos.isEmpty ? _buildEmptyState() : _buildTodoList(),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Build the app bar with stats
  PreferredSizeWidget _buildAppBar(Map<String, int> stats) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Tasks',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (stats['total']! > 0)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${stats['completed']} of ${stats['total']} completed',
                key: ValueKey('${stats['completed']}-${stats['total']}'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      toolbarHeight: 80,
      actions: [
        if (_todos.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear completed',
            onPressed: _clearCompleted,
          ),
      ],
    );
  }

  /// Build the animated todo list
  Widget _buildTodoList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _todos.length,
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 80, // Space for FAB
      ),
      itemBuilder: (context, index, animation) {
        return TodoItem(
          todo: _todos[index],
          animation: animation,
          onToggle: () => _toggleTodo(index),
          onDelete: () => _deleteTodo(index),
        );
      },
    );
  }

  /// Build empty state with animation
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tasks yet!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// Build the floating action button with animation
  Widget _buildFAB() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  /// Clear all completed todos
  void _clearCompleted() {
    final completedIndices = <int>[];
    for (int i = _todos.length - 1; i >= 0; i--) {
      if (_todos[i].isCompleted) {
        completedIndices.add(i);
      }
    }

    if (completedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed tasks to clear'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Delete with staggered animation
    for (int i = 0; i < completedIndices.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (completedIndices[i] < _todos.length) {
          _deleteTodo(completedIndices[i]);
        }
      });
    }
  }
}

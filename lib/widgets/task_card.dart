import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.completed
                  ? AppTheme.successColor
                  : Colors.transparent,
              border: Border.all(
                color: task.completed ? AppTheme.successColor : Colors.white24,
                width: 2,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          '${task.icon} ${task.title}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? Colors.white54 : Colors.white,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 12,
              color: Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              '${task.time} • ${_getRepeatText(task.repeat)}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        trailing: _CategoryBadge(category: task.category),
      ),
    );
  }

  String _getRepeatText(TaskRepeat repeat) {
    switch (repeat) {
      case TaskRepeat.daily:
        return 'Diario';
      case TaskRepeat.weekly:
        return 'Semanal';
      case TaskRepeat.monthly:
        return 'Mensual';
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final TaskCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(category).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getName(category),
        style: TextStyle(
          color: _getColor(category),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.food:
        return Colors.orange;
      case TaskCategory.cleaning:
        return Colors.blue;
      case TaskCategory.mental:
        return Colors.purple;
      case TaskCategory.shopping:
        return Colors.green;
    }
  }

  String _getName(TaskCategory category) {
    switch (category) {
      case TaskCategory.food:
        return 'Comida';
      case TaskCategory.cleaning:
        return 'Limpieza';
      case TaskCategory.mental:
        return 'Salud';
      case TaskCategory.shopping:
        return 'Compras';
    }
  }
}

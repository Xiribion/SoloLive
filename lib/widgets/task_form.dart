import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class TaskForm extends StatefulWidget {
  final Task? task;

  const TaskForm({super.key, this.task});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late TextEditingController _titleController;
  late TimeOfDay _selectedTime;
  late TaskCategory _selectedCategory;
  late TaskRepeat _selectedRepeat;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');

    if (task != null) {
      final parts = task.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      _selectedCategory = task.category;
      _selectedRepeat = task.repeat;
    } else {
      _selectedTime = TimeOfDay.now();
      _selectedCategory = TaskCategory.food;
      _selectedRepeat = TaskRepeat.daily;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.task == null ? 'Nueva Tarea' : 'Editar Tarea',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.task != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: _deleteTask,
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            autofocus: widget.task == null,
            decoration: InputDecoration(
              hintText: 'Ej. Tomar medicinas',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.task_alt),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  label: 'Hora',
                  value: _selectedTime.format(context),
                  icon: Icons.access_time,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelector(
                  label: 'Repetir',
                  value: _getRepeatName(_selectedRepeat),
                  icon: Icons.repeat,
                  onTap: _showRepeatPicker,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Categoría',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getCategoryName(cat)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.task == null ? 'Crear Tarea' : 'Guardar Cambios',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white54),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRepeatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: TaskRepeat.values.map((r) {
          return ListTile(
            title: Text(_getRepeatName(r)),
            leading: _selectedRepeat == r
                ? const Icon(Icons.check, color: AppTheme.primaryColor)
                : const SizedBox(width: 24),
            onTap: () {
              setState(() => _selectedRepeat = r);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _saveTask() {
    if (_titleController.text.isEmpty) return;

    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    if (widget.task == null) {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text,
        category: _selectedCategory,
        time: timeStr,
        repeat: _selectedRepeat,
        icon: _getCategoryIcon(_selectedCategory),
      );
      Provider.of<AppProvider>(context, listen: false).addTask(newTask);
    } else {
      final updatedTask = Task(
        id: widget.task!.id,
        title: _titleController.text,
        category: _selectedCategory,
        time: timeStr,
        repeat: _selectedRepeat,
        icon: _getCategoryIcon(_selectedCategory),
        completed: widget.task!.completed,
        lastCompletedDate: widget.task!.lastCompletedDate,
      );
      Provider.of<AppProvider>(context, listen: false).updateTask(updatedTask);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.task == null ? 'Tarea creada' : 'Tarea actualizada',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta tarea?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppProvider>(
                context,
                listen: false,
              ).deleteTask(widget.task!.id);
              Navigator.pop(ctx); // Dialog
              Navigator.pop(context); // Sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tarea eliminada'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.food:
        return 'Comida';
      case TaskCategory.cleaning:
        return 'Limpieza';
      case TaskCategory.mental:
        return 'Salud Mental';
      case TaskCategory.shopping:
        return 'Compras';
    }
  }

  String _getCategoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.food:
        return '🍳';
      case TaskCategory.cleaning:
        return '🧹';
      case TaskCategory.mental:
        return '🧘';
      case TaskCategory.shopping:
        return '🛒';
    }
  }

  String _getRepeatName(TaskRepeat r) {
    switch (r) {
      case TaskRepeat.daily:
        return 'Diario';
      case TaskRepeat.weekly:
        return 'Semanal';
      case TaskRepeat.monthly:
        return 'Mensual';
    }
  }
}

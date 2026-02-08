import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class EmergencyContact {
  String name;
  String phone;

  EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(name: json['name'], phone: json['phone']);
  }
}

class AppProvider with ChangeNotifier {
  String _userName = 'Amigo';
  List<Task> _tasks = [];
  String? _mood;
  int _water = 0;
  EmergencyContact? _emergencyContact;
  Map<String, List<int>> _history = {}; // Date -> List<TaskID>
  DateTime _registrationDate = DateTime.now();

  String get userName => _userName;
  List<Task> get tasks => _tasks;
  String? get mood => _mood;
  int get water => _water;
  EmergencyContact? get emergencyContact => _emergencyContact;
  Map<String, List<int>> get history => _history;
  DateTime get registrationDate => _registrationDate;

  static const String _storageKey = 'soloLifeData';

  Future<void> init() async {
    await _loadData();
    _checkAndResetDailyTasks();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_storageKey);

    if (dataString != null) {
      final data = json.decode(dataString);
      _userName = data['userName'] ?? 'Amigo';

      if (data['tasks'] != null) {
        _tasks = (data['tasks'] as List).map((t) => Task.fromJson(t)).toList();
      } else {
        _tasks = _getDefaultTasks();
      }

      if (data['history'] != null) {
        Map<String, dynamic> historyMap = data['history'];
        _history = historyMap.map(
          (key, value) => MapEntry(key, List<int>.from(value)),
        );
      }

      _mood = data['mood'];
      _water = data['water'] ?? 0;

      if (data['emergencyContact'] != null) {
        _emergencyContact = EmergencyContact.fromJson(data['emergencyContact']);
      }

      if (data['registrationDate'] != null) {
        _registrationDate = DateTime.parse(data['registrationDate']);
      }
    } else {
      _tasks = _getDefaultTasks();
      _registrationDate = DateTime.now();
      _saveData();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'userName': _userName,
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'history': _history,
      'mood': _mood,
      'water': _water,
      'emergencyContact': _emergencyContact?.toJson(),
      'registrationDate': _registrationDate.toIso8601String(),
      'lastSaved': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_storageKey, json.encode(data));
    notifyListeners();
  }

  void _checkAndResetDailyTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString('lastReset');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastReset != today) {
      for (var task in _tasks) {
        if (task.repeat == TaskRepeat.daily) {
          task.completed = false;
        }
      }
      _mood = null;
      _water = 0;
      await prefs.setString('lastReset', today);
      _saveData();
    }
  }

  void toggleTask(int taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final wasCompleted = task.completed;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Update task
      task.completed = !wasCompleted;
      task.lastCompletedDate = task.completed ? today : null;
      _tasks[taskIndex] = task; // Trigger update

      // Update history
      if (task.completed) {
        if (!_history.containsKey(today)) {
          _history[today] = [];
        }
        if (!_history[today]!.contains(taskId)) {
          _history[today]!.add(taskId);
        }
      } else {
        if (_history.containsKey(today)) {
          _history[today]!.remove(taskId);
        }
      }

      _saveData();
    }
  }

  void setMood(String mood) {
    _mood = mood;
    _saveData();
  }

  void addWater() {
    _water = (_water + 1) % 9;
    _saveData();
  }

  void updateUserName(String name) {
    _userName = name;
    _saveData();
  }

  void setEmergencyContact(String name, String phone) {
    _emergencyContact = EmergencyContact(name: name, phone: phone);
    _saveData();
  }

  void addTask(Task task) {
    _tasks.add(task);
    _saveData();
  }

  void deleteTask(int taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveData();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveData();
    }
  }

  void resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('lastReset');
    await init();
  }

  // Getters for stats
  int get completedTodayCount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _tasks
        .where((t) => t.completed && t.lastCompletedDate == today)
        .length;
  }

  int get pendingTodayCount {
    return getTodayTasks().where((t) => !t.completed).length;
  }

  List<Task> getTodayTasks() {
    return getTasksForDate(DateTime.now());
  }

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) => _shouldShowOnDate(task, date)).toList()
      ..sort((a, b) {
        return a.time.compareTo(b.time);
      });
  }

  bool _shouldShowOnDate(Task task, DateTime date) {
    if (task.repeat == TaskRepeat.daily) return true;
    if (task.repeat == TaskRepeat.weekly && date.weekday == DateTime.monday)
      return true;
    if (task.repeat == TaskRepeat.monthly && date.day == 1) return true;
    return false;
  }

  List<int> getWeeklyStats() {
    final now = DateTime.now();
    List<int> stats = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      stats.add(_history[dateStr]?.length ?? 0);
    }
    return stats;
  }

  double getCompletionRate() {
    if (getTodayTasks().isEmpty) return 0.0;
    return completedTodayCount / getTodayTasks().length;
  }

  String getBestCategory() {
    if (_history.isEmpty) return 'Ninguna';

    Map<TaskCategory, int> counts = {};
    for (var completions in _history.values) {
      for (var taskId in completions) {
        final task = _tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => Task(
            id: -1,
            title: '',
            time: '',
            category: TaskCategory.food,
            icon: '',
            repeat: TaskRepeat.daily,
          ),
        );
        if (task.id != -1) {
          counts[task.category] = (counts[task.category] ?? 0) + 1;
        }
      }
    }

    if (counts.isEmpty) return 'Ninguna';

    var sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    switch (sortedEntries.first.key) {
      case TaskCategory.food:
        return 'Alimentación';
      case TaskCategory.cleaning:
        return 'Limpieza';
      case TaskCategory.mental:
        return 'Salud Mental';
      case TaskCategory.shopping:
        return 'Compras';
    }
  }

  int get daysSinceRegistration {
    return DateTime.now().difference(_registrationDate).inDays + 1;
  }

  int get currentStreak {
    // Check backwards from yesterday
    int streak = 0;
    final now = DateTime.now();
    // Logic: if today has ANY completion, streak continues? Or if YESTERDAY had completion?
    // Let's say: Streak of days with at least 1 task completed.

    // Check today
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    if ((_history[todayStr]?.length ?? 0) > 0) streak++;

    for (int i = 1; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if ((_history[dateStr]?.length ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalCompletedTasks {
    int total = 0;
    _history.forEach((key, value) {
      total += value.length;
    });
    return total;
  }

  List<Task> _getDefaultTasks() {
    return [
      // Food
      Task(
        id: 1,
        category: TaskCategory.food,
        title: 'Desayuno',
        time: '08:00',
        repeat: TaskRepeat.daily,
        icon: '🍳',
      ),
      Task(
        id: 2,
        category: TaskCategory.food,
        title: 'Almuerzo',
        time: '13:00',
        repeat: TaskRepeat.daily,
        icon: '🍽️',
      ),
      Task(
        id: 3,
        category: TaskCategory.food,
        title: 'Cena',
        time: '20:00',
        repeat: TaskRepeat.daily,
        icon: '🍲',
      ),
      Task(
        id: 4,
        category: TaskCategory.food,
        title: 'Beber agua (2L)',
        time: '10:00',
        repeat: TaskRepeat.daily,
        icon: '💧',
      ),
      Task(
        id: 5,
        category: TaskCategory.food,
        title: 'Snack saludable',
        time: '16:00',
        repeat: TaskRepeat.daily,
        icon: '🍎',
      ),

      // Cleaning
      Task(
        id: 6,
        category: TaskCategory.cleaning,
        title: 'Hacer la cama',
        time: '09:00',
        repeat: TaskRepeat.daily,
        icon: '🛏️',
      ),
      Task(
        id: 7,
        category: TaskCategory.cleaning,
        title: 'Lavar platos',
        time: '21:00',
        repeat: TaskRepeat.daily,
        icon: '🍽️',
      ),
      Task(
        id: 8,
        category: TaskCategory.cleaning,
        title: 'Limpiar cocina',
        time: '19:00',
        repeat: TaskRepeat.weekly,
        icon: '🧽',
      ),
      Task(
        id: 9,
        category: TaskCategory.cleaning,
        title: 'Aspirar/Barrer',
        time: '10:00',
        repeat: TaskRepeat.weekly,
        icon: '🧹',
      ),

      // Mental
      Task(
        id: 12,
        category: TaskCategory.mental,
        title: 'Meditación',
        time: '07:30',
        repeat: TaskRepeat.daily,
        icon: '🧘',
      ),
      Task(
        id: 13,
        category: TaskCategory.mental,
        title: 'Caminar',
        time: '18:00',
        repeat: TaskRepeat.daily,
        icon: '🏃',
      ),
      Task(
        id: 14,
        category: TaskCategory.mental,
        title: 'Journaling',
        time: '22:00',
        repeat: TaskRepeat.daily,
        icon: '📝',
      ),

      // Shopping
      Task(
        id: 17,
        category: TaskCategory.shopping,
        title: 'Comprar frutas',
        time: '10:00',
        repeat: TaskRepeat.weekly,
        icon: '🥬',
      ),
      Task(
        id: 18,
        category: TaskCategory.shopping,
        title: 'Limpieza',
        time: '10:00',
        repeat: TaskRepeat.monthly,
        icon: '🧴',
      ),
    ];
  }
}

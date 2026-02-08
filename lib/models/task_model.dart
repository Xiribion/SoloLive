enum TaskCategory { food, cleaning, mental, shopping }

enum TaskRepeat { daily, weekly, monthly }

class Task {
  final int id;
  final String title;
  final TaskCategory category;
  final String time; // HH:mm
  final TaskRepeat repeat;
  bool completed;
  String? lastCompletedDate; // YYYY-MM-DD
  final String icon;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.time,
    required this.repeat,
    this.completed = false,
    this.lastCompletedDate,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.toString().split('.').last,
      'time': time,
      'repeat': repeat.toString().split('.').last,
      'completed': completed,
      'lastCompletedDate': lastCompletedDate,
      'icon': icon,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      category: TaskCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TaskCategory.food,
      ),
      time: json['time'],
      repeat: TaskRepeat.values.firstWhere(
        (e) => e.toString().split('.').last == json['repeat'],
        orElse: () => TaskRepeat.daily,
      ),
      completed: json['completed'],
      lastCompletedDate: json['lastCompletedDate'],
      icon: json['icon'],
    );
  }

  Task copyWith({bool? completed, String? lastCompletedDate}) {
    return Task(
      id: id,
      title: title,
      category: category,
      time: time,
      repeat: repeat,
      completed: completed ?? this.completed,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      icon: icon,
    );
  }
}

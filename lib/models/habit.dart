import 'dart:convert';
import 'dart:math';

class HabitCategory {
  final String name;
  final String colorHex;
  final String iconName;

  const HabitCategory({
    required this.name,
    required this.colorHex,
    required this.iconName,
  });
}

const List<HabitCategory> categories = [
  HabitCategory(name: 'Fitness', colorHex: '#10b981', iconName: 'fitness_center'),
  HabitCategory(name: 'Reading', colorHex: '#3b82f6', iconName: 'book'),
  HabitCategory(name: 'Wellness', colorHex: '#8b5cf6', iconName: 'spa'),
  HabitCategory(name: 'Productivity', colorHex: '#f59e0b', iconName: 'work'),
  HabitCategory(name: 'Health', colorHex: '#ef4444', iconName: 'favorite'),
  HabitCategory(name: 'Mindset', colorHex: '#ec4899', iconName: 'psychology'),
];

class Habit {
  final String id;
  final String name;
  final int categoryIndex;
  final String description;
  final String emoji;
  final int goalDays;
  final String createdAt;
  final Map<String, bool> done; // key: YYYY-MM-DD, value: true/false

  Habit({
    required this.id,
    required this.name,
    required this.categoryIndex,
    this.description = '',
    this.emoji = '⭐',
    this.goalDays = 30,
    required this.createdAt,
    required this.done,
  });

  // Serialization to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryIndex': categoryIndex,
      'description': description,
      'emoji': emoji,
      'goalDays': goalDays,
      'createdAt': createdAt,
      'done': done,
    };
  }

  // De-serialization from Map
  factory Habit.fromMap(Map<String, dynamic> map) {
    // Safely cast done map
    Map<String, bool> parsedDone = {};
    if (map['done'] != null) {
      (map['done'] as Map).forEach((key, value) {
        parsedDone[key.toString()] = value as bool;
      });
    }
    
    return Habit(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      categoryIndex: map['categoryIndex'] as int? ?? 0,
      description: map['description']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '⭐',
      goalDays: map['goalDays'] as int? ?? 30,
      createdAt: map['createdAt']?.toString() ?? '',
      done: parsedDone,
    );
  }

  // JSON helpers
  String toJson() => json.encode(toMap());
  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));

  // Clone with changes
  Habit copyWith({
    String? id,
    String? name,
    int? categoryIndex,
    String? description,
    String? emoji,
    int? goalDays,
    String? createdAt,
    Map<String, bool>? done,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      goalDays: goalDays ?? this.goalDays,
      createdAt: createdAt ?? this.createdAt,
      done: done ?? Map<String, bool>.from(this.done),
    );
  }

  // Seed data generator matching targets: [16, 25, 27, 27, 24, 24, 25, 20, 29, 30]
  static List<Habit> getInitialHabits() {
    final today = DateTime.now();
    final oldestDate = today.subtract(const Duration(days: 30));
    final oldestStr = formatDateKey(oldestDate);

    final List<Habit> list = [
      Habit(id: '1', name: 'Wake up at 05:00', categoryIndex: 4, description: 'Wake up early to seize the day.', emoji: '⏰', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '2', name: 'Gym', categoryIndex: 0, description: 'Strength or cardio workout.', emoji: '💪', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '3', name: 'Stop Watching Porn', categoryIndex: 2, description: 'Avoid triggers, maintain mental clarity.', emoji: '🔞', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '4', name: 'Reading / Learning', categoryIndex: 1, description: 'Read non-fiction, articles, or learn a skill.', emoji: '📖', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '5', name: 'Budget Tracking', categoryIndex: 3, description: 'Log all expenses and stay within budget.', emoji: '💰', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '6', name: 'Project Work', categoryIndex: 3, description: 'Focus time on development or writing.', emoji: '🎯', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '7', name: 'No Alcohol', categoryIndex: 4, description: 'Avoid alcoholic beverages completely.', emoji: '🚫', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '8', name: 'Social Media Detox', categoryIndex: 2, description: 'Restrict mindless scrolling.', emoji: '🌿', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '9', name: 'Goal Journaling', categoryIndex: 5, description: 'Review goals and write thoughts.', emoji: '📒', goalDays: 30, createdAt: oldestStr, done: {}),
      Habit(id: '10', name: 'Cold Shower', categoryIndex: 2, description: 'Kickstart circulation and alertness.', emoji: '🚿', goalDays: 30, createdAt: oldestStr, done: {}),
    ];

    final targetActuals = [16, 25, 27, 27, 24, 24, 25, 20, 29, 30];

    for (int idx = 0; idx < list.length; idx++) {
      final habit = list[idx];
      final actualCount = targetActuals[idx];
      final daysIndices = List<int>.generate(30, (i) => i);

      // Reproducible pseudo-shuffle to distribute completed days uniquely
      if (actualCount < 30) {
        for (int i = daysIndices.length - 1; i > 0; i--) {
          final j = (idx * 11 + i * 7) % (i + 1);
          final temp = daysIndices[i];
          daysIndices[i] = daysIndices[j];
          daysIndices[j] = temp;
        }
      }

      final selectedIndices = daysIndices.take(actualCount).toSet();

      for (int d = 1; d <= 30; d++) {
        final date = today.subtract(Duration(days: d));
        final dateStr = formatDateKey(date);

        if (selectedIndices.contains(d - 1)) {
          habit.done[dateStr] = true;
        }
      }
    }

    return list;
  }

  // Format Helper YYYY-MM-DD
  static String formatDateKey(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // Calculate streaks
  Map<String, int> calculateStreaks() {
    final dates = done.keys.where((k) => done[k] == true).toList();
    if (dates.isEmpty) {
      return {'current': 0, 'max': 0};
    }
    
    // Sort dates descending for current streak
    dates.sort((a, b) => b.compareTo(a));
    
    int currentStreak = 0;
    final todayStr = formatDateKey(DateTime.now());
    final yesterdayStr = formatDateKey(DateTime.now().subtract(const Duration(days: 1)));
    
    bool completedToday = done[todayStr] ?? false;
    bool completedYesterday = done[yesterdayStr] ?? false;
    
    if (completedToday || completedYesterday) {
      DateTime checkDate = completedToday ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1));
      while (true) {
        final checkStr = formatDateKey(checkDate);
        if (done[checkStr] == true) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
    
    // Sort ascending for max streak calculation
    dates.sort((a, b) => a.compareTo(b));
    
    int maxStreak = 0;
    int tempStreak = 0;
    DateTime? prevDate;
    
    for (final dateStr in dates) {
      final currDate = DateTime.parse(dateStr);
      if (prevDate == null) {
        tempStreak = 1;
      } else {
        final diffDays = currDate.difference(prevDate).inDays;
        if (diffDays == 1) {
          tempStreak++;
        } else if (diffDays > 1) {
          maxStreak = max(maxStreak, tempStreak);
          tempStreak = 1;
        }
      }
      prevDate = currDate;
    }
    maxStreak = max(maxStreak, tempStreak);
    
    return {'current': currentStreak, 'max': maxStreak};
  }
}

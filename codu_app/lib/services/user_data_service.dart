import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataService {
  // Private constructor for singleton pattern
  UserDataService._internal();

  static final UserDataService _instance = UserDataService._internal();

  factory UserDataService() => _instance;

  // Helper to get active user ID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Default subjects data
  final List<Map<String, dynamic>> _defaultSubjects = [
    {
      'title': 'Introduction to Python',
      'lessons': 54,
      'color1': 0xFF8F93EA,
      'color2': 0xFF7076E3,
      'lang': 'Python',
    },
    {
      'title': 'Introduction to C++',
      'lessons': 59,
      'color1': 0xFF7A9EFF,
      'color2': 0xFF5672E5,
      'lang': 'C++',
    },
    {
      'title': 'Introduction to Javascript',
      'lessons': 54,
      'color1': 0xFFFFD56B,
      'color2': 0xFFE5A93B,
      'lang': 'Javascript',
    },
    {
      'title': 'Introduction to Java',
      'lessons': 64,
      'color1': 0xFFFF8B8B,
      'color2': 0xFFE55353,
      'lang': 'Java',
    },
  ];

  // Default history progress data
  final List<Map<String, dynamic>> _defaultHistory = [
    {
      'title': 'Introduction to Python',
      'lessons': 54,
      'completed': 41,
      'status': 'In Progress',
      'lang': 'Python',
    },
    {
      'title': 'Introduction to C++',
      'lessons': 59,
      'completed': 59,
      'status': 'Completed',
      'lang': 'C++',
    },
    {
      'title': 'Introduction to Javascript',
      'lessons': 54,
      'completed': 41,
      'status': 'In Progress',
      'lang': 'Javascript',
    },
    {
      'title': 'Introduction to Java',
      'lessons': 64,
      'completed': 64,
      'status': 'Completed',
      'lang': 'Java',
    },
  ];

  // Default lessons data
  final List<Map<String, dynamic>> _defaultLessons = [
    // Python Lessons
    {
      'id': 'py-1',
      'subject': 'Python',
      'title': 'Introduction & Setup',
      'duration': '10 mins',
      'status': 'Completed',
    },
    {
      'id': 'py-2',
      'subject': 'Python',
      'title': 'Variables & Data Types',
      'duration': '15 mins',
      'status': 'Completed',
    },
    {
      'id': 'py-3',
      'subject': 'Python',
      'title': 'Conditional Statements',
      'duration': '12 mins',
      'status': 'In Progress',
    },
    {
      'id': 'py-4',
      'subject': 'Python',
      'title': 'Loops & Iterations',
      'duration': '18 mins',
      'status': 'Locked',
    },
    {
      'id': 'py-5',
      'subject': 'Python',
      'title': 'Functions & Modules',
      'duration': '20 mins',
      'status': 'Locked',
    },
    // C++ Lessons
    {
      'id': 'cpp-1',
      'subject': 'C++',
      'title': 'C++ Basic Syntax',
      'duration': '12 mins',
      'status': 'Completed',
    },
    {
      'id': 'cpp-2',
      'subject': 'C++',
      'title': 'Pointers & References',
      'duration': '25 mins',
      'status': 'Completed',
    },
    {
      'id': 'cpp-3',
      'subject': 'C++',
      'title': 'Memory Management',
      'duration': '22 mins',
      'status': 'Completed',
    },
    {
      'id': 'cpp-4',
      'subject': 'C++',
      'title': 'Object-Oriented Programming',
      'duration': '30 mins',
      'status': 'Completed',
    },
    // Javascript Lessons
    {
      'id': 'js-1',
      'subject': 'Javascript',
      'title': 'JS Engine & Scope',
      'duration': '15 mins',
      'status': 'Completed',
    },
    {
      'id': 'js-2',
      'subject': 'Javascript',
      'title': 'DOM Manipulation',
      'duration': '20 mins',
      'status': 'In Progress',
    },
    {
      'id': 'js-3',
      'subject': 'Javascript',
      'title': 'Asynchronous JS (Promises)',
      'duration': '25 mins',
      'status': 'Locked',
    },
    // Java Lessons
    {
      'id': 'java-1',
      'subject': 'Java',
      'title': 'JVM & JDK Setup',
      'duration': '10 mins',
      'status': 'Completed',
    },
    {
      'id': 'java-2',
      'subject': 'Java',
      'title': 'Classes & Inheritance',
      'duration': '18 mins',
      'status': 'Completed',
    },
    {
      'id': 'java-3',
      'subject': 'Java',
      'title': 'Multithreading in Java',
      'duration': '28 mins',
      'status': 'Completed',
    },
  ];

  // Track app open date and calculate streak
  Future<void> trackAppOpen() async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    List<String> dates = prefs.getStringList('open_dates_$uid') ?? [];
    
    // If dates list is empty, initialize with today's date so they start with a 1-day streak
    if (dates.isEmpty) {
      dates.add(todayStr);
      await prefs.setStringList('open_dates_$uid', dates);
      await prefs.setInt('streak_$uid', 1);
      return;
    }

    if (!dates.contains(todayStr)) {
      dates.add(todayStr);
      dates.sort();
      await prefs.setStringList('open_dates_$uid', dates);

      int calculatedStreak = _calculateConsecutiveStreak(dates);
      await prefs.setInt('streak_$uid', calculatedStreak);
    }
  }

  // Calculate consecutive days ending with the latest date
  int _calculateConsecutiveStreak(List<String> dates) {
    if (dates.isEmpty) return 0;

    List<DateTime> parsedDates = dates.map((d) {
      final parts = d.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }).toList();

    parsedDates.sort();

    int streak = 1;
    for (int i = parsedDates.length - 1; i > 0; i--) {
      final difference = parsedDates[i].difference(parsedDates[i - 1]).inDays;
      if (difference == 1) {
        streak++;
      } else if (difference > 1) {
        break; // Streak broken
      }
    }
    return streak;
  }

  // Load Streak
  Future<int> getStreak() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();

    List<String> dates = prefs.getStringList('open_dates_$uid') ?? [];
    if (dates.isEmpty) {
      // Auto-initialize
      await trackAppOpen();
      dates = prefs.getStringList('open_dates_$uid') ?? [];
    }

    // Verify if streak has expired (more than 1 day since last open)
    if (dates.isNotEmpty) {
      dates.sort();
      final latestStr = dates.last;
      final parts = latestStr.split('-');
      final latestDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diffInDays = today.difference(latestDate).inDays;

      if (diffInDays > 1) {
        // Streak is broken! Reset to 0
        await prefs.setInt('streak_$uid', 0);
        return 0;
      }
    }

    return prefs.getInt('streak_$uid') ?? 0;
  }

  // Save Streak
  Future<void> saveStreak(int streak) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_$uid', streak);

    // Also update open_dates to match the new streak
    final now = DateTime.now();
    List<String> dates = [];
    for (int i = streak - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      dates.add("${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
    }
    await prefs.setStringList('open_dates_$uid', dates);
  }

  // Load Trophies / Stars
  Future<int> getTrophies() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('trophies_$uid') ?? 150; // Default to 150
  }

  // Save Trophies / Stars
  Future<void> saveTrophies(int trophies) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trophies_$uid', trophies);
  }

  // Load Avatar Index
  Future<int> getAvatarIndex() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('avatar_$uid') ?? 0;
  }

  // Save Avatar Index
  Future<void> saveAvatarIndex(int index) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('avatar_$uid', index);
  }

  // Load Subjects
  Future<List<Map<String, dynamic>>> getSubjects() async {
    final uid = _uid;
    if (uid == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('subjects_$uid');
    if (jsonStr == null) {
      return List<Map<String, dynamic>>.from(_defaultSubjects);
    }
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return List<Map<String, dynamic>>.from(_defaultSubjects);
    }
  }

  // Save Subjects
  Future<void> saveSubjects(List<Map<String, dynamic>> subjects) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = json.encode(subjects);
    await prefs.setString('subjects_$uid', jsonStr);
  }

  // Load History
  Future<List<Map<String, dynamic>>> getHistory() async {
    final uid = _uid;
    if (uid == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('history_$uid');
    if (jsonStr == null) {
      return List<Map<String, dynamic>>.from(_defaultHistory);
    }
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return List<Map<String, dynamic>>.from(_defaultHistory);
    }
  }

  // Save History
  Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = json.encode(history);
    await prefs.setString('history_$uid', jsonStr);
  }

  // Load Lessons
  Future<List<Map<String, dynamic>>> getLessons() async {
    final uid = _uid;
    if (uid == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('lessons_$uid');
    if (jsonStr == null) {
      return List<Map<String, dynamic>>.from(_defaultLessons);
    }
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return List<Map<String, dynamic>>.from(_defaultLessons);
    }
  }

  // Save Lessons
  Future<void> saveLessons(List<Map<String, dynamic>> lessons) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = json.encode(lessons);
    await prefs.setString('lessons_$uid', jsonStr);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'friend_service.dart';

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
      'lessons': 45,
      'color1': 0xFF8F93EA,
      'color2': 0xFF7076E3,
      'lang': 'Python',
    },
    {
      'title': 'Introduction to C++',
      'lessons': 45,
      'color1': 0xFF7A9EFF,
      'color2': 0xFF5672E5,
      'lang': 'C++',
    },
    {
      'title': 'Introduction to Javascript',
      'lessons': 45,
      'color1': 0xFFFFD56B,
      'color2': 0xFFE5A93B,
      'lang': 'Javascript',
    },
    {
      'title': 'Introduction to Java',
      'lessons': 45,
      'color1': 0xFFFF8B8B,
      'color2': 0xFFE55353,
      'lang': 'Java',
    },
  ];

  // Default history progress data
  final List<Map<String, dynamic>> _defaultHistory = [
    {
      'title': 'Introduction to Python',
      'lessons': 45,
      'completed': 0,
      'status': 'Not Started',
      'lang': 'Python',
    },
    {
      'title': 'Introduction to C++',
      'lessons': 45,
      'completed': 0,
      'status': 'Not Started',
      'lang': 'C++',
    },
    {
      'title': 'Introduction to Javascript',
      'lessons': 45,
      'completed': 0,
      'status': 'Not Started',
      'lang': 'Javascript',
    },
    {
      'title': 'Introduction to Java',
      'lessons': 45,
      'completed': 0,
      'status': 'Not Started',
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

  // Track app open date and check if streak is broken
  Future<void> trackAppOpen() async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();

    String? lastIncrementStr = prefs.getString('last_streak_increment_date_$uid');
    if (lastIncrementStr == null) {
      final openDates = prefs.getStringList('open_dates_$uid');
      if (openDates != null && openDates.isNotEmpty) {
        openDates.sort();
        lastIncrementStr = openDates.last;
        await prefs.setString('last_streak_increment_date_$uid', lastIncrementStr);
      }
    }

    if (lastIncrementStr != null) {
      final parts = lastIncrementStr.split('-');
      final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diffInDays = today.difference(lastDate).inDays;

      if (diffInDays > 1) {
        // Streak is broken! Reset to 0
        await prefs.setInt('streak_$uid', 0);
      }
    }
  }

  // Load Streak
  Future<int> getStreak() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();

    String? lastIncrementStr = prefs.getString('last_streak_increment_date_$uid');
    if (lastIncrementStr == null) {
      final openDates = prefs.getStringList('open_dates_$uid');
      if (openDates != null && openDates.isNotEmpty) {
        openDates.sort();
        lastIncrementStr = openDates.last;
        await prefs.setString('last_streak_increment_date_$uid', lastIncrementStr);
      }
    }

    if (lastIncrementStr != null) {
      final parts = lastIncrementStr.split('-');
      final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diffInDays = today.difference(lastDate).inDays;

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

    if (streak == 0) {
      await prefs.remove('last_streak_increment_date_$uid');
    } else {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      await prefs.setString('last_streak_increment_date_$uid', todayStr);
    }
  }

  // Load Trophies / Stars
  Future<int> getTrophies() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('trophies_$uid') ?? 0; // Default to 0
  }

  // Save Trophies / Stars
  Future<void> saveTrophies(int trophies) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trophies_$uid', trophies);
  }

  // Load Wins
  Future<int> getWins() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wins_$uid') ?? 0;
  }

  // Save Wins
  Future<void> saveWins(int wins) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wins_$uid', wins);
  }

  // Load Losses
  Future<int> getLosses() async {
    final uid = _uid;
    if (uid == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('losses_$uid') ?? 0;
  }

  // Save Losses
  Future<void> saveLosses(int losses) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('losses_$uid', losses);
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
      final List<Map<String, dynamic>> list = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      for (var item in list) {
        item['lessons'] = 45;
        if (item['lang'] == 'Phyton') {
          item['lang'] = 'Python';
        }
      }
      return list;
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
      final List<Map<String, dynamic>> list = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      for (var item in list) {
        item['lessons'] = 45;
        if (item['lang'] == 'Phyton') {
          item['lang'] = 'Python';
        }
      }
      return list;
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
      final List<Map<String, dynamic>> list = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      for (var item in list) {
        if (item['subject'] == 'Phyton') {
          item['subject'] = 'Python';
        }
      }
      return list;
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

  // Load custom display name (overrides Firebase displayName)
  Future<String?> getDisplayName() async {
    final uid = _uid;
    if (uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('display_name_$uid');
  }

  // Save custom display name locally and to Firebase Auth
  Future<void> saveDisplayName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name_$uid', name);
    // Also push to Firebase so other devices see it
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    } catch (_) {
      // If Firebase update fails, local storage is still saved
    }
  }

  // Get stars achieved for each level in a subject
  Future<Map<int, int>> getLevelStars(String subjectName) async {
    final uid = _uid;
    if (uid == null) return {};
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('level_stars_${uid}_$subjectName');
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      return decoded.map((key, val) => MapEntry(int.parse(key), val as int));
    } catch (_) {
      return {};
    }
  }

  // Save stars achieved for a level
  Future<void> saveLevelStars(String subjectName, int levelNumber, int stars) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final starsMap = await getLevelStars(subjectName);
    final int currentStars = starsMap[levelNumber] ?? 0;
    if (stars > currentStars) {
      starsMap[levelNumber] = stars;
      final String jsonStr = json.encode(starsMap.map((key, val) => MapEntry(key.toString(), val)));
      await prefs.setString('level_stars_${uid}_$subjectName', jsonStr);
    }
  }

  // Complete the current level/lesson for a subject and sync rewards
  Future<void> completeLevel(String subjectName, int levelNumber, int stars) async {
    final history = await getHistory();
    final dbSubject = subjectName;

    // Save stars for this level
    await saveLevelStars(dbSubject, levelNumber, stars);

    for (int i = 0; i < history.length; i++) {
      if (history[i]['lang'] == dbSubject) {
        int currentCompleted = history[i]['completed'] ?? 0;
        int totalLessons = history[i]['lessons'] ?? 45;

        // If they complete the current active level, advance progression
        if (levelNumber == currentCompleted + 1) {
          if (currentCompleted < totalLessons) {
            history[i]['completed'] = currentCompleted + 1;
            if (history[i]['completed'] == totalLessons) {
              history[i]['status'] = 'Completed';
            } else {
              history[i]['status'] = 'In Progress';
            }
          }
        }
        break;
      }
    }
    await saveHistory(history);

    // Award +10 trophies
    int currentTrophies = await getTrophies();
    await saveTrophies(currentTrophies + 10);

    // Increase streak by 1 only if they haven't completed a course level today
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid;
    if (uid != null) {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      String? lastIncrementStr = prefs.getString('last_streak_increment_date_$uid');
      if (lastIncrementStr == null) {
        final openDates = prefs.getStringList('open_dates_$uid');
        if (openDates != null && openDates.isNotEmpty) {
          openDates.sort();
          lastIncrementStr = openDates.last;
          await prefs.setString('last_streak_increment_date_$uid', lastIncrementStr);
        }
      }

      int currentStreak = prefs.getInt('streak_$uid') ?? 0;
      int newStreak = currentStreak;

      if (lastIncrementStr == null || currentStreak == 0) {
        // First increment ever or starting fresh
        newStreak = 1;
        await prefs.setInt('streak_$uid', newStreak);
        await prefs.setString('last_streak_increment_date_$uid', todayStr);
      } else {
        final parts = lastIncrementStr.split('-');
        final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final today = DateTime(now.year, now.month, now.day);
        final diffInDays = today.difference(lastDate).inDays;

        if (diffInDays == 1) {
          // Consecutive completion! +1 to streak
          newStreak = currentStreak + 1;
          await prefs.setInt('streak_$uid', newStreak);
          await prefs.setString('last_streak_increment_date_$uid', todayStr);
        } else if (diffInDays > 1) {
          // Missed a day or more, reset streak to 1 since they completed a level today
          newStreak = 1;
          await prefs.setInt('streak_$uid', newStreak);
          await prefs.setString('last_streak_increment_date_$uid', todayStr);
        }
        // If diffInDays == 0, they already completed a level today. No streak update.
      }
    }

    // Sync to Firestore in the background (non-blocking)
    FriendService().syncUserToFirestore().catchError((e) {
      debugPrint("Failed to sync progress to Firestore: $e");
    });
  }

  // Sync all user data down from Firestore into SharedPreferences
  Future<void> syncDataFromFirestore() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();

      // Sync streak
      if (data.containsKey('streak')) {
        await prefs.setInt('streak_$uid', data['streak'] as int);
      }
      // Sync trophies
      if (data.containsKey('trophies')) {
        await prefs.setInt('trophies_$uid', data['trophies'] as int);
      }
      // Sync avatarIndex
      if (data.containsKey('avatarIndex')) {
        await prefs.setInt('avatar_$uid', data['avatarIndex'] as int);
      }
      // Sync wins
      if (data.containsKey('wins')) {
        await prefs.setInt('wins_$uid', data['wins'] as int);
      }
      // Sync losses
      if (data.containsKey('losses')) {
        await prefs.setInt('losses_$uid', data['losses'] as int);
      }
      // Sync custom display name
      if (data.containsKey('displayName')) {
        await prefs.setString('display_name_$uid', data['displayName'] as String);
      }

      // Sync courses progress (history and level stars)
      if (data.containsKey('courses')) {
        final coursesMap = data['courses'] as Map<String, dynamic>?;
        if (coursesMap != null) {
          final List<String> subjects = ['Python', 'C++', 'Javascript', 'Java'];
          final List<Map<String, dynamic>> history = [];

          for (final subject in subjects) {
            final String docId = subject.toLowerCase();
            if (coursesMap.containsKey(docId)) {
              final courseData = coursesMap[docId] as Map<String, dynamic>?;
              if (courseData != null) {
                final int completedCount = (courseData['completed'] ?? 0) as int;
                
                // Reconstruct history item
                history.add({
                  'title': 'Introduction to $subject',
                  'lessons': 45,
                  'completed': completedCount,
                  'status': completedCount == 45 
                      ? 'Completed' 
                      : (completedCount > 0 ? 'In Progress' : 'Not Started'),
                  'lang': subject,
                });

                // Reconstruct level stars map
                final levelsData = courseData['levels'] as Map<String, dynamic>?;
                if (levelsData != null) {
                  final Map<String, int> starsMap = {};
                  levelsData.forEach((key, val) {
                    starsMap[key] = val as int;
                  });
                  final String starsJson = json.encode(starsMap);
                  await prefs.setString('level_stars_${uid}_$subject', starsJson);
                }
              }
            } else {
              // Add default history item if missing
              history.add({
                'title': 'Introduction to $subject',
                'lessons': 45,
                'completed': 0,
                'status': 'Not Started',
                'lang': subject,
              });
            }
          }

          if (history.isNotEmpty) {
            await prefs.setString('history_$uid', json.encode(history));
          }
        }
      }
      debugPrint("Profile progress synced down from Firestore successfully!");
    } catch (e) {
      debugPrint("Failed to sync progress down from Firestore: $e");
    }
  }
}

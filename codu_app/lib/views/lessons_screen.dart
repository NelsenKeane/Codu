import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  String _selectedSubject = 'All';

  final List<Map<String, dynamic>> _subjects = [
    {'name': 'All', 'color': AppColors.purple},
    {'name': 'Python', 'color': Colors.blue},
    {'name': 'C++', 'color': Colors.indigo},
    {'name': 'Javascript', 'color': Colors.amber.shade700},
    {'name': 'Java', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _lessons = [
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

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final filteredLessons = _selectedSubject == 'All'
        ? _lessons
        : _lessons.where((l) => l['subject'] == _selectedSubject).toList();

    return Scaffold(
      backgroundColor: AppColors.skyBlue,
      body: Column(
        children: [
          // Header with Back Button and Speech Bubble style
          _buildHeader(statusBarHeight),
          
          // Filters row
          _buildFilters(),

          // Lessons list card container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _buildLessonCard(lesson, index + 1);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return Padding(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Back chevron button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "All Lessons",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final isSelected = _selectedSubject == subject['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubject = subject['name'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  subject['name'],
                  style: GoogleFonts.nunito(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson, int index) {
    Color statusColor;
    IconData statusIcon;

    switch (lesson['status']) {
      case 'Completed':
        statusColor = AppColors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'In Progress':
        statusColor = AppColors.yellow;
        statusIcon = Icons.play_circle_fill;
        break;
      default:
        statusColor = AppColors.textGrey;
        statusIcon = Icons.lock_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            index.toString().padLeft(2, '0'),
            style: GoogleFonts.nunito(
              color: statusColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          lesson['title'],
          style: GoogleFonts.nunito(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              lesson['subject'],
              style: GoogleFonts.nunito(
                color: AppColors.textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.textGrey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              lesson['duration'],
              style: GoogleFonts.nunito(
                color: AppColors.textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          statusIcon,
          color: statusColor,
          size: 28,
        ),
      ),
    );
  }
}

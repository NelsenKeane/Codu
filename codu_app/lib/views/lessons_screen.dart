import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/user_data_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  String _selectedSubject = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];

  final List<Map<String, dynamic>> _subjects = [
    {'name': 'All', 'color': AppColors.purple},
    {'name': 'Python', 'color': Colors.blue},
    {'name': 'C++', 'color': Colors.indigo},
    {'name': 'Javascript', 'color': Colors.amber.shade700},
    {'name': 'Java', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final lessons = await UserDataService().getLessons();
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLessonStatus(Map<String, dynamic> lesson, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    // 1. Update the lesson status in local list
    for (var l in _lessons) {
      if (l['id'] == lesson['id']) {
        l['status'] = newStatus;
      }
    }

    // 2. Save lessons
    await UserDataService().saveLessons(_lessons);

    // 3. Recalculate subjects and history progress
    final history = await UserDataService().getHistory();

    // Group lessons by subject and update status
    for (var subjectName in ['Python', 'C++', 'Javascript', 'Java']) {
      final subjectLessons = _lessons.where((l) => l['subject'] == subjectName).toList();
      final totalCount = subjectLessons.length;
      if (totalCount == 0) continue;

      final completedCount = subjectLessons.where((l) => l['status'] == 'Completed').toList().length;
      final completedPercent = completedCount / totalCount;

      // Update history card progress
      for (var h in history) {
        if (h['lang'] == subjectName) {
          int mockTotal = h['lessons'] ?? 50;
          h['completed'] = (completedPercent * mockTotal).round();
          if (completedPercent == 1.0) {
            h['status'] = 'Completed';
          } else if (completedPercent == 0.0) {
            h['status'] = 'Locked'; // Or not started, but let's keep status consistent
          } else {
            h['status'] = 'In Progress';
          }
        }
      }
    }

    await UserDataService().saveHistory(history);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showStatusDialog(Map<String, dynamic> lesson) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Update Lesson Status",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update Status",
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson['title'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatusOption(lesson, "Completed", AppColors.green, Icons.check_circle),
                  _buildStatusOption(lesson, "In Progress", AppColors.yellow, Icons.play_circle_fill),
                  _buildStatusOption(lesson, "Locked", AppColors.textGrey, Icons.lock_outline),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.nunito(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(Map<String, dynamic> lesson, String status, Color color, IconData icon) {
    final isSelected = lesson['status'] == status;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _updateLessonStatus(lesson, status);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: GoogleFonts.nunito(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                        ),
                      )
                    : ListView.builder(
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
        onTap: () => _showStatusDialog(lesson),
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/user_data_service.dart';
import '../services/friend_service.dart';
import 'lessons_screen.dart';
import 'levels_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  int _streak = 0;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingData = true;
  String? _selectedSubjectForLevels;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await UserDataService().trackAppOpen();
    final streak = await UserDataService().getStreak();
    final subjects = await UserDataService().getSubjects();
    final history = await UserDataService().getHistory();
    
    // Sync profile to Firestore asynchronously
    FriendService().syncUserToFirestore().catchError((e) {
      debugPrint("Failed to sync user to firestore: $e");
    });

    if (mounted) {
      setState(() {
        _streak = streak;
        _subjects = subjects;
        _history = history;
        _isLoadingData = false;
      });
    }
  }

  void _showStreakDialog() {
    final TextEditingController controller = TextEditingController(text: _streak.toString());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Update Streak",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
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
                    "Update Streak Count",
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 36, color: AppColors.textGrey),
                        onPressed: () {
                          int val = int.tryParse(controller.text) ?? 0;
                          if (val > 0) {
                            controller.text = (val - 1).toString();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 36, color: AppColors.green),
                        onPressed: () {
                          int val = int.tryParse(controller.text) ?? 0;
                          controller.text = (val + 1).toString();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB020),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          int? newStreak = int.tryParse(controller.text);
                          if (newStreak != null && newStreak >= 0) {
                            await UserDataService().saveStreak(newStreak);
                            _loadUserData();
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Text(
                          "Save",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHomeDashboard(double statusBarHeight) {
    final filteredSubjects = _subjects
        .where((s) => s['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final filteredHistory = _history
        .where((h) => h['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Top Header Area (Sky blue, mascot, speech bubble)
              _buildHeader(statusBarHeight),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(36),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Search bar & Streak Row
                _buildSearchRow(),
                const SizedBox(height: 28),

                // Subjects Header
                _buildSectionHeader(
                  title: "Subjects",
                  onViewAll: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LessonsScreen()),
                    );
                    _loadUserData();
                  },
                ),
                const SizedBox(height: 16),

                // Horizontal Subjects list
                _buildSubjectsList(filteredSubjects),
                const SizedBox(height: 28),

                // History Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "History",
                    style: GoogleFonts.nunito(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid-like History cards
                _buildHistoryCards(filteredHistory),
                
                // Extra padding for the floating navigation bar
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderScreen({
    required String title,
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      color: AppColors.cardBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.nunito(
                  color: AppColors.textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: AppColors.skyBlue,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    Widget bodyContent;
    switch (_selectedNavIndex) {
      case 0:
        bodyContent = _buildHomeDashboard(statusBarHeight);
        break;
      case 1:
        bodyContent = LevelsScreen(initialSubject: _selectedSubjectForLevels);
        break;
      case 2:
        bodyContent = _buildPlaceholderScreen(
          title: "Explore",
          icon: Icons.public_rounded,
          color: Colors.teal,
          message: "Connect and share your coding journey with users worldwide!",
        );
        break;
      case 3:
        bodyContent = const LeaderboardScreen();
        break;
      case 4:
        bodyContent = const ProfileScreen();
        break;
      default:
        bodyContent = _buildHomeDashboard(statusBarHeight);
    }

    return Scaffold(
      backgroundColor: AppColors.skyBlue,
      body: Stack(
        children: [
          // SVG background for tabs that don't have their own (home, explore, leaderboard)
          if (_selectedNavIndex != 1 && _selectedNavIndex != 4)
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/codu_background_pattern_mobile_soft.svg',
                fit: BoxFit.cover,
              ),
            ),
          // Screen Body Content
          Positioned.fill(child: bodyContent),

          // Floating Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }
  // Header Area Widget
  Widget _buildHeader(double statusBarHeight) {
    return Padding(
      padding: EdgeInsets.only(
        top: statusBarHeight + 10,
        left: 20,
        right: 20,
      ),
      child: _buildMascotHeader(),
    );
  }

  // Mascot + Speech Bubble Widget
  Widget _buildMascotHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mascot
        Transform.translate(
          offset: const Offset(0, 35),
          child: Container(
            width: 175,
            height: 175,
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/codu_mascot.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Speech Bubble
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Hey there! How can\nI help you today?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                // Bubble Tail pointing to the mascot
                Positioned(
                  left: -6,
                  bottom: 16,
                  child: RotationTransition(
                    turns: const AlwaysStoppedAnimation(45 / 360),
                    child: Container(
                      width: 12,
                      height: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Search and Streak badge Row Widget
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // Search input field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.black.withValues(alpha: 0.3),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.nunito(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: GoogleFonts.nunito(
                          color: Colors.black.withValues(alpha: 0.25),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Streak counter
          GestureDetector(
            onTap: _showStreakDialog,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3F4D59), // Slate dark color
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  const Text(
                    "🔥",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$_streak",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section Header with View All Widget
  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              "View All",
              style: GoogleFonts.nunito(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Scroll list of subjects
  Widget _buildSubjectsList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Text(
          "No subjects found.",
          style: GoogleFonts.nunito(
            color: AppColors.textGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final subject = list[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSubjectForLevels = subject['lang'];
                _selectedNavIndex = 1;
              });
            },
            child: Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(subject['color1'] is int ? subject['color1'] : int.parse(subject['color1'].toString())),
                    Color(subject['color2'] is int ? subject['color2'] : int.parse(subject['color2'].toString())),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color(subject['color2'] is int ? subject['color2'] : int.parse(subject['color2'].toString())).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLanguageBadge(subject['lang']),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['title'],
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${subject['lessons']} Lessons",
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Grid/List of progress cards
  Widget _buildHistoryCards(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Text(
          "No history found.",
          style: GoogleFonts.nunito(
            color: AppColors.textGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Creating rows of 2 columns
    List<Widget> rows = [];
    for (int i = 0; i < list.length; i += 2) {
      Widget leftCard = _buildHistoryCard(list[i]);
      Widget rightCard = (i + 1 < list.length)
          ? _buildHistoryCard(list[i + 1])
          : Expanded(child: Container());

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              Expanded(child: leftCard),
              const SizedBox(width: 12),
              Expanded(child: rightCard),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    bool isCompleted = item['status'] == 'Completed';
    Color themeColor = isCompleted ? AppColors.green : AppColors.yellow;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubjectForLevels = item['lang'];
          _selectedNavIndex = 1;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with badge and language icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLanguageBadge(item['lang']),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['status'],
                    style: GoogleFonts.nunito(
                      color: themeColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              item['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              "${item['lessons']} Lessons",
              style: GoogleFonts.nunito(
                color: AppColors.textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            // Progress text
            Text(
              "${item['completed']} of ${item['lessons']} Completed",
              style: GoogleFonts.nunito(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: item['completed'] / item['lessons'],
                backgroundColor: const Color(0xFFF0F2F6),
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Language logo builder
  Widget _buildLanguageBadge(String lang) {
    switch (lang) {
      case 'Python':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "🐍",
            style: TextStyle(fontSize: 18),
          ),
        );
      case 'C++':
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF5E73E5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            "C+",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        );
      case 'Javascript':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF7DF1E),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            "JS",
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        );
      case 'Java':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "☕",
            style: TextStyle(fontSize: 16),
          ),
        );
      default:
        return const SizedBox(width: 32, height: 32);
    }
  }

  // Floating Bottom Navigation Bar Widget
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, Colors.orange),
          _buildNavItem(1, Icons.menu_book_rounded, Colors.blue),
          _buildNavItem(2, Icons.sports_esports_rounded, Colors.teal),
          _buildNavItem(3, Icons.emoji_events_rounded, Colors.orangeAccent),
          _buildNavItem(4, Icons.person_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, Color activeColor) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
        _loadUserData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? activeColor : AppColors.textGrey,
          size: 28,
        ),
      ),
    );
  }
}

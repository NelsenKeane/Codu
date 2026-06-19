import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Subjects data
  final List<Map<String, dynamic>> _subjects = [
    {
      'title': 'Introduction to Python',
      'lessons': 54,
      'color1': Color(0xFF8F93EA),
      'color2': Color(0xFF7076E3),
      'lang': 'Python',
    },
    {
      'title': 'Introduction to C++',
      'lessons': 59,
      'color1': Color(0xFF7A9EFF),
      'color2': Color(0xFF5672E5),
      'lang': 'C++',
    },
    {
      'title': 'Introduction to Javascript',
      'lessons': 54,
      'color1': Color(0xFFFFD56B),
      'color2': Color(0xFFE5A93B),
      'lang': 'Javascript',
    },
    {
      'title': 'Introduction to Java',
      'lessons': 64,
      'color1': Color(0xFFFF8B8B),
      'color2': Color(0xFFE55353),
      'lang': 'Java',
    },
  ];

  // History progress data
  final List<Map<String, dynamic>> _history = [
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

  Widget _buildHomeDashboard(double statusBarHeight) {
    final filteredSubjects = _subjects
        .where((s) => s['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final filteredHistory = _history
        .where((h) => h['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Header Area (Sky blue, mascot, speech bubble)
          _buildHeader(statusBarHeight),

          // Content Area (Light Blue Background)
          Container(
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
                  onViewAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LessonsScreen()),
                    );
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
        ],
      ),
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    Widget bodyContent;
    switch (_selectedNavIndex) {
      case 0:
        bodyContent = _buildHomeDashboard(statusBarHeight);
        break;
      case 1:
        bodyContent = const LevelsScreen();
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
      backgroundColor: _selectedNavIndex == 1 ? const Color(0xFF56CCF2) : AppColors.skyBlue,
      body: Stack(
        children: [
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Decorative Speech Bubble Silhouettes (Lighter sky blue)
        Positioned(
          top: statusBarHeight - 10,
          right: -25,
          child: Icon(
            Icons.chat_bubble,
            size: 110,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          top: statusBarHeight + 35,
          left: -25,
          child: Icon(
            Icons.chat_bubble,
            size: 90,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          bottom: 5,
          right: 35,
          child: Icon(
            Icons.chat_bubble,
            size: 70,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 100,
          child: Icon(
            Icons.code_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),

        // Header Content
        Padding(
          padding: EdgeInsets.only(
            top: statusBarHeight + 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code icon </> in the top-left
              _buildCodeLogo(),
              const SizedBox(height: 8),
              // Mascot and Speech Bubble
              _buildMascotHeader(),
            ],
          ),
        ),
      ],
    );
  }

  // Code Icon Logo Widget
  Widget _buildCodeLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        "</>",
        style: GoogleFonts.nunito(
          color: const Color(0xFF1D83B5).withValues(alpha: 0.6),
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }

  // Mascot + Speech Bubble Widget
  Widget _buildMascotHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mascot
        Container(
          width: 130,
          height: 130,
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/images/codu_mascot.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        // Speech Bubble
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
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
          Container(
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
                  "20",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
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
          return Container(
            width: 200,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [subject['color1'], subject['color2']],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: subject['color2'].withValues(alpha: 0.3),
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

    return Container(
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

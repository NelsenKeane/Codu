import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isGlobalSelected = true;

  // Mock Global data
  final List<Map<String, dynamic>> _globalRankings = [
    // Top 3 (on podium)
    {'rank': 1, 'name': 'Kevin', 'score': 2850, 'emoji': '🤓', 'bgColor': Color(0xFFFFD56B)},
    {'rank': 2, 'name': 'Emma', 'score': 1500, 'emoji': '👧', 'bgColor': Color(0xFF8F93EA)},
    {'rank': 3, 'name': 'Max', 'score': 1000, 'emoji': '👦', 'bgColor': Color(0xFFFF8B8B)},
    // Rest of list
    {'rank': 4, 'name': 'Brandon', 'score': 980, 'emoji': '👨‍💻', 'bgColor': Color(0xFF7A9EFF)},
    {'rank': 5, 'name': 'Bentley', 'score': 950, 'emoji': '🧒', 'bgColor': Color(0xFF8CEEAD)},
    {'rank': 6, 'name': 'Sophia', 'score': 920, 'emoji': '👩‍💻', 'bgColor': Color(0xFFFFB5E8)},
    {'rank': 7, 'name': 'Lucas', 'score': 890, 'emoji': '👦', 'bgColor': Color(0xFFBFFCC6)},
    {'rank': 8, 'name': 'Olivia', 'score': 850, 'emoji': '👧', 'bgColor': Color(0xFFFFC5A5)},
  ];

  // Mock Friends data
  final List<Map<String, dynamic>> _friendsRankings = [
    // Top 3 (on podium for friends)
    {'rank': 1, 'name': 'Emma', 'score': 1500, 'emoji': '👧', 'bgColor': Color(0xFF8F93EA)},
    {'rank': 2, 'name': 'You', 'score': 1250, 'emoji': '🦖', 'bgColor': Color(0xFF95FF7A), 'isSelf': true},
    {'rank': 3, 'name': 'Max', 'score': 1000, 'emoji': '👦', 'bgColor': Color(0xFFFF8B8B)},
    // Rest of list
    {'rank': 4, 'name': 'Bentley', 'score': 950, 'emoji': '🧒', 'bgColor': Color(0xFF8CEEAD)},
    {'rank': 5, 'name': 'Sophia', 'score': 920, 'emoji': '👩‍💻', 'bgColor': Color(0xFFFFB5E8)},
  ];

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final List<Map<String, dynamic>> rankings = _isGlobalSelected ? _globalRankings : _friendsRankings;

    // Separate podium (top 3) from the scrollable list below (ranks 4+)
    final List<Map<String, dynamic>> topThree = rankings.where((r) => r['rank'] <= 3).toList();
    final List<Map<String, dynamic>> remainingList = rankings.where((r) => r['rank'] > 3).toList();

    // Sort podium so order is 2nd (left), 1st (middle), 3rd (right)
    Map<String, dynamic>? firstPlace = topThree.firstWhere((r) => r['rank'] == 1, orElse: () => topThree[0]);
    Map<String, dynamic>? secondPlace = topThree.firstWhere((r) => r['rank'] == 2, orElse: () => topThree[1]);
    Map<String, dynamic>? thirdPlace = topThree.firstWhere((r) => r['rank'] == 3, orElse: () => topThree[2]);

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2), // Matching sky blue background
      body: Stack(
        children: [
          // 1. Background Silhouettes
          _buildBackgroundDecor(statusBarHeight),

          // 2. Top Header Info (Title + Trophy Score)
          Positioned(
            top: statusBarHeight + 16,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Leaderboard",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                _buildTrophyScoreCapsule(),
              ],
            ),
          ),

          // 3. Scrollable Content Area (Starts below header)
          Positioned(
            top: statusBarHeight + 84,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 110), // Padding below for bottom floating nav
                  children: [
                    // Tab Selector (Global vs Friends)
                    _buildTabSelector(),
                    const SizedBox(height: 24),

                    // Podium Area (Top 3)
                    _buildPodium(secondPlace, firstPlace, thirdPlace),
                    const SizedBox(height: 24),

                    // Ranking List Divider / Line
                    const Divider(
                      height: 1,
                      color: Color(0xFFE5E5E5),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),

                    // Scrollable rankings list (ranks 4+)
                    ...remainingList.map((player) => _buildPlayerRankCard(player)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating background silhouettes for premium look
  Widget _buildBackgroundDecor(double statusBarHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 10,
            left: 30,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 70,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 50,
            right: 110,
            child: Icon(
              Icons.code_rounded,
              size: 50,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  // Dark slate capsule showing Trophy count
  Widget _buildTrophyScoreCapsule() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3F4D59), // Dark slate background
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "🏆",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            "150",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Dual capsule tab selector: Global vs Friends
  Widget _buildTabSelector() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: [
          // Global Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isGlobalSelected = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isGlobalSelected ? const Color(0xFF8F93EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: _isGlobalSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8F93EA).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      color: _isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Global",
                      style: GoogleFonts.nunito(
                        color: _isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Friends Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isGlobalSelected = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isGlobalSelected ? const Color(0xFF8F93EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: !_isGlobalSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8F93EA).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: !_isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Friends",
                      style: GoogleFonts.nunito(
                        color: !_isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Winding Podium Row (Emma, Kevin, Max)
  Widget _buildPodium(
    Map<String, dynamic> second,
    Map<String, dynamic> first,
    Map<String, dynamic> third,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place Column
        _buildPodiumColumn(
          player: second,
          podiumHeight: 125,
          columnColor: const Color(0xFF8F93EA),
          badgeBorderColor: const Color(0xFFB0B0B0),
          badgeFillColor: const Color(0xFFCCCCCC),
        ),
        const SizedBox(width: 12),
        // 1st Place Column
        _buildPodiumColumn(
          player: first,
          podiumHeight: 165,
          columnColor: const Color(0xFF8F93EA),
          badgeBorderColor: const Color(0xFFD97E00),
          badgeFillColor: const Color(0xFFFFC043),
        ),
        const SizedBox(width: 12),
        // 3rd Place Column
        _buildPodiumColumn(
          player: third,
          podiumHeight: 95,
          columnColor: const Color(0xFF8F93EA),
          badgeBorderColor: const Color(0xFF8E5A2A),
          badgeFillColor: const Color(0xFFCD7F32),
        ),
      ],
    );
  }

  // Individual Podium Column builder
  Widget _buildPodiumColumn({
    required Map<String, dynamic> player,
    required double podiumHeight,
    required Color columnColor,
    required Color badgeBorderColor,
    required Color badgeFillColor,
  }) {
    final bool isSelf = player['isSelf'] ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle with character emoji
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: player['bgColor'],
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelf ? const Color(0xFFFFD56B) : Colors.white,
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            player['emoji'],
            style: const TextStyle(fontSize: 38),
          ),
        ),
        const SizedBox(height: 10),
        // Podium block
        Container(
          width: 90,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: columnColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: columnColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Hexagonal rank badge
              HexagonBadge(
                text: player['rank'].toString(),
                fillColor: badgeFillColor,
                borderColor: badgeBorderColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              // Name text
              Text(
                player['name'],
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              // Trophy Score row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "🏆",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    player['score'].toString(),
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Row card for ranks 4 and below
  Widget _buildPlayerRankCard(Map<String, dynamic> player) {
    final bool isSelf = player['isSelf'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFFFFFBEA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf ? const Color(0xFFFFD56B) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Green Hexagonal Rank Badge
          HexagonBadge(
            text: player['rank'].toString(),
            fillColor: const Color(0xFF8CEEAD),
            borderColor: const Color(0xFF46B830),
            size: 30,
          ),
          const SizedBox(width: 16),

          // User Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: player['bgColor'],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              player['emoji'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              player['name'],
              style: GoogleFonts.nunito(
                color: const Color(0xFF2B2D42),
                fontWeight: isSelf ? FontWeight.w900 : FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),

          // Trophy Score
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🏆",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                player['score'].toString(),
                style: GoogleFonts.nunito(
                  color: const Color(0xFF2B2D42),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- CUSTOM HEXAGON BADGE WIDGET ----------------

class HexagonBadge extends StatelessWidget {
  final String text;
  final Color fillColor;
  final Color borderColor;
  final double size;

  const HexagonBadge({
    super.key,
    required this.text,
    required this.fillColor,
    required this.borderColor,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.866), // Aspect ratio for point-up hexagon is 1 : sqrt(3)/2
      painter: HexagonPainter(fillColor: fillColor, borderColor: borderColor),
      child: SizedBox(
        width: size,
        height: size * 0.866,
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  HexagonPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    // Standard point-up hexagon:
    // Vertices starting at Top Center (w/2, 0) and moving clockwise
    path.moveTo(w / 2, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w / 2, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor || oldDelegate.borderColor != borderColor;
  }
}

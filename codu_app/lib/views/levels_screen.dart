import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_data_service.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  String _selectedSubject = 'Phyton'; // Mockup spelling

  final List<String> _subjects = ['Phyton', 'C++', 'Javascript', 'Java'];

  int _streak = 0;
  int _trophies = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final streak = await UserDataService().getStreak();
    final trophies = await UserDataService().getTrophies();
    if (mounted) {
      setState(() {
        _streak = streak;
        _trophies = trophies;
        _isLoading = false;
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
                      color: const Color(0xFF1D83B5),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 36, color: Colors.grey),
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
                            color: const Color(0xFF1D83B5),
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 36, color: Colors.green),
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
                            color: Colors.grey,
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
                          if (mounted) Navigator.of(context).pop();
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

  void _showTrophiesDialog() {
    final TextEditingController controller = TextEditingController(text: _trophies.toString());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Update Trophies",
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
                    "Update Trophies Count",
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF1D83B5),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 36, color: Colors.grey),
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
                            color: const Color(0xFF1D83B5),
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 36, color: Colors.green),
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
                            color: Colors.grey,
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
                          int? newTrophies = int.tryParse(controller.text);
                          if (newTrophies != null && newTrophies >= 0) {
                            await UserDataService().saveTrophies(newTrophies);
                            _loadUserData();
                          }
                          if (mounted) Navigator.of(context).pop();
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

  // Map subjects to emojis for the dropdown
  String _getSubjectEmoji(String subject) {
    switch (subject) {
      case 'Phyton':
        return '🐍';
      case 'C++':
        return '🔵';
      case 'Javascript':
        return '💛';
      case 'Java':
        return '☕';
      default:
        return '📚';
    }
  }

  // Winding path math formula: calculates horizontal center based on vertical Y coordinate
  double _getCurveX(double y, double screenWidth) {
    final double centerX = screenWidth / 2;
    // Keep amplitude within bounds so nodes don't overflow the screen edges
    final double amplitude = screenWidth * 0.22;
    // Path frequency determines how tight the curves are
    const double frequency = 0.005;
    // Using a vertical offset phase shift to align the first nodes
    return centerX + amplitude * math.sin(y * frequency + 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Height of our scrollable winding path canvas
    const double pathCanvasHeight = 1600.0;

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2), // Vibrant sky blue from mockup
      body: Stack(
        children: [
          // 1. Background Silhouettes
          _buildBackgroundDecor(statusBarHeight),

          // 2. Scrollable Winding Path
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: statusBarHeight + 90, // Room for header
                bottom: 120, // Room for floating navigation bar
              ),
              child: SizedBox(
                height: pathCanvasHeight,
                width: screenWidth,
                child: Stack(
                  children: [
                    // The painted winding road ribbon
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WindingPathPainter(
                          screenWidth: screenWidth,
                          totalHeight: pathCanvasHeight,
                          curveFormula: _getCurveX,
                        ),
                      ),
                    ),

                    // Level Nodes along the path
                    ..._buildLevelNodes(screenWidth),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Header (Subject Selector & Stats)
          Positioned(
            top: statusBarHeight + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSubjectDropdown(),
                _buildStatsRow(),
              ],
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
            top: statusBarHeight + 120,
            left: -20,
            child: Icon(
              Icons.code_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 350,
            right: -10,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 600,
            left: 30,
            child: Icon(
              Icons.menu_book_rounded,
              size: 70,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 850,
            right: 40,
            child: Icon(
              Icons.code_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 1100,
            left: -15,
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 1300,
            right: 20,
            child: Icon(
              Icons.terminal_rounded,
              size: 60,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  // Purple pill-shaped dropdown for selecting subjects
  Widget _buildSubjectDropdown() {
    return PopupMenuButton<String>(
      onSelected: (String val) {
        setState(() {
          _selectedSubject = val;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 50),
      itemBuilder: (BuildContext context) {
        return _subjects.map((String subject) {
          return PopupMenuItem<String>(
            value: subject,
            child: Row(
              children: [
                Text(
                  _getSubjectEmoji(subject),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  subject,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8F93EA), Color(0xFF7076E3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7076E3).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getSubjectEmoji(_selectedSubject),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedSubject,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Row for streak (fire) and stars stats
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Streak / Fire Capsule
        GestureDetector(
          onTap: _showStreakDialog,
          child: Container(
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
              children: [
                const Text(
                  "🔥",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  "$_streak",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Star Capsule
        GestureDetector(
          onTap: _showTrophiesDialog,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF3F4D59),
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
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFD56B), // Golden yellow star
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  "$_trophies",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Generates the level nodes positioned along the mathematical winding path
  List<Widget> _buildLevelNodes(double screenWidth) {
    // We define our levels list: Y positions, type (completed, active, locked, crown), level number/label, stars
    final List<Map<String, dynamic>> levels = [
      // Top nodes are locked in the mockup
      {'y': 100.0, 'type': 'locked', 'icon': Icons.lock_rounded},
      {'y': 240.0, 'type': 'locked', 'icon': Icons.lock_rounded},
      {'y': 380.0, 'type': 'locked', 'icon': Icons.lock_rounded},
      {'y': 520.0, 'type': 'locked', 'icon': Icons.lock_rounded},
      {'y': 660.0, 'type': 'crown', 'icon': Icons.workspace_premium_rounded}, // Crown boss level
      {'y': 800.0, 'type': 'locked', 'icon': Icons.lock_rounded},
      {'y': 940.0, 'type': 'active', 'level': 3}, // Level 3 active
      {'y': 1080.0, 'type': 'completed', 'stars': 2}, // Completed with 2/3 stars
      {'y': 1220.0, 'type': 'completed', 'stars': 3}, // Completed with 3/3 stars
      {'y': 1360.0, 'type': 'completed', 'stars': 3},
    ];

    return levels.map((level) {
      final double nodeY = level['y'];
      final String type = level['type'];
      final double nodeX = _getCurveX(nodeY, screenWidth);
      const double nodeSize = 76.0;

      Widget nodeChild;
      if (type == 'completed') {
        nodeChild = LevelNodeCompleted(stars: level['stars']);
      } else if (type == 'active') {
        nodeChild = LevelNodeActive(levelNumber: level['level']);
      } else if (type == 'crown') {
        nodeChild = LevelNodeCrown();
      } else {
        nodeChild = LevelNodeLocked();
      }

      return Positioned(
        left: nodeX - (nodeSize / 2),
        top: nodeY,
        child: SizedBox(
          width: nodeSize + 40, // extra width for stars overflow
          height: nodeSize + 60, // extra height for tooltips and stars
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              nodeChild,
            ],
          ),
        ),
      );
    }).toList();
  }
}

// Custom Painter to draw the smooth wavy blue path
class WindingPathPainter extends CustomPainter {
  final double screenWidth;
  final double totalHeight;
  final double Function(double y, double width) curveFormula;

  WindingPathPainter({
    required this.screenWidth,
    required this.totalHeight,
    required this.curveFormula,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw background road outline / shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 92
      ..strokeCap = StrokeCap.round;

    final shadowPath = Path();
    shadowPath.moveTo(curveFormula(0, screenWidth), 0);
    for (double y = 2; y <= totalHeight; y += 4) {
      shadowPath.lineTo(curveFormula(y, screenWidth), y);
    }
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Draw active inner ribbon (light blue road)
    final pathPaint = Paint()
      ..color = const Color(0xFFCBEBFC) // Soft bright blue path ribbon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 76
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(curveFormula(0, screenWidth), 0);
    for (double y = 2; y <= totalHeight; y += 4) {
      path.lineTo(curveFormula(y, screenWidth), y);
    }
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant WindingPathPainter oldDelegate) {
    return oldDelegate.screenWidth != screenWidth || oldDelegate.totalHeight != totalHeight;
  }
}

// ---------------- LEVEL NODES COMPONENT WIDGETS ----------------

// Base structure for 3D circular button used by nodes
class Duo3dCircleButton extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback? onPressed;
  final double size;

  const Duo3dCircleButton({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    this.onPressed,
    this.size = 72,
  });

  @override
  State<Duo3dCircleButton> createState() => _Duo3dCircleButtonState();
}

class _Duo3dCircleButtonState extends State<Duo3dCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 6.0;
    final double translation = _isPressed ? shadowHeight : 0;

    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
      child: Container(
        width: widget.size,
        height: widget.size + shadowHeight,
        decoration: BoxDecoration(
          color: widget.shadowColor,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              top: translation,
              left: 0,
              right: 0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.faceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. Completed Node (Yellow Circle, checkmark inside, stars above)
class LevelNodeCompleted extends StatelessWidget {
  final int stars;

  const LevelNodeCompleted({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 3D Circle Node
        Duo3dCircleButton(
          faceColor: const Color(0xFFFFC043), // Rich golden yellow
          shadowColor: const Color(0xFFE5921E), // Darker yellow/orange shadow
          onPressed: () {},
          size: 72,
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        // Floating Stars Arc
        Positioned(
          top: -24,
          child: _buildStarsArc(),
        ),
      ],
    );
  }

  // Draw 3 stars in a slight arc
  Widget _buildStarsArc() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left Star (rotated, lower)
        Transform.rotate(
          angle: -0.25,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              Icons.star_rounded,
              color: stars >= 1 ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 2),
        // Middle Star (centered, higher, larger)
        Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Icon(
            Icons.star_rounded,
            color: stars >= 2 ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.25),
            size: 26,
          ),
        ),
        const SizedBox(width: 2),
        // Right Star (rotated, lower)
        Transform.rotate(
          angle: 0.25,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              Icons.star_rounded,
              color: stars >= 3 ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// 2. Active Node (Yellow circle with white star inside, white "Level 3" tooltip bubble above)
class LevelNodeActive extends StatelessWidget {
  final int levelNumber;

  const LevelNodeActive({super.key, required this.levelNumber});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 3D Circle Node
        Duo3dCircleButton(
          faceColor: const Color(0xFFFFC043),
          shadowColor: const Color(0xFFE5921E),
          onPressed: () {},
          size: 72,
          child: const Icon(
            Icons.star_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        // Tooltip speech bubble above
        Positioned(
          top: -46,
          child: _buildTooltipBubble(),
        ),
      ],
    );
  }

  Widget _buildTooltipBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The bubble container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            "Level $levelNumber",
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        // Triangle tail pointing down
        CustomPaint(
          size: const Size(12, 6),
          painter: TrianglePainter(),
        ),
      ],
    );
  }
}

// Draws the tail pointing down on speech bubble
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Locked Node (Gray Circle, padlock inside)
class LevelNodeLocked extends StatelessWidget {
  const LevelNodeLocked({super.key});

  @override
  Widget build(BuildContext context) {
    return Duo3dCircleButton(
      faceColor: const Color(0xFFCCCCCC), // Soft gray
      shadowColor: const Color(0xFFB0B0B0), // Darker gray shadow
      onPressed: null, // Disabled
      size: 72,
      child: const Icon(
        Icons.lock_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}

// 4. Crown Node (Silver/Gray Circle, crown inside)
class LevelNodeCrown extends StatelessWidget {
  const LevelNodeCrown({super.key});

  @override
  Widget build(BuildContext context) {
    return Duo3dCircleButton(
      faceColor: const Color(0xFFCCCCCC),
      shadowColor: const Color(0xFFB0B0B0),
      onPressed: null,
      size: 72,
      child: const Icon(
        Icons.workspace_premium_rounded, // Best fit for premium crown representation
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

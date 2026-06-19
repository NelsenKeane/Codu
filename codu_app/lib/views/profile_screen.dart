import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _avatarIndex = 0;

  // List of interactive avatars the user can cycle through
  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '🤓', 'bgColor': const Color(0xFFFFD56B), 'name': 'Nerd'},
    {'emoji': '👨‍💻', 'bgColor': const Color(0xFF7A9EFF), 'name': 'Coder'},
    {'emoji': '😎', 'bgColor': const Color(0xFFFF8B8B), 'name': 'Cool'},
    {'emoji': '🦁', 'bgColor': const Color(0xFF8CEEAD), 'name': 'Lion'},
    {'emoji': '🦖', 'bgColor': const Color(0xFF95FF7A), 'name': 'Dino'},
  ];

  void _cycleAvatar() {
    setState(() {
      _avatarIndex = (_avatarIndex + 1) % _avatars.length;
    });
  }

  // Method to show Friend List dialog
  void _showFriendsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Friends",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 350,
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
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Friend List",
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        _buildFriendRow("Kevin", "🤓", const Color(0xFFFFD56B), "Online"),
                        _buildFriendRow("Emma", "👧", const Color(0xFF8F93EA), "Online"),
                        _buildFriendRow("Max", "👦", const Color(0xFFFF8B8B), "Away"),
                        _buildFriendRow("Brandon", "👨‍💻", const Color(0xFF7A9EFF), "Offline"),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Close",
                        style: GoogleFonts.nunito(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildFriendRow(String name, String emoji, Color bgColor, String status) {
    Color statusColor = status == "Online"
        ? Colors.green
        : (status == "Away" ? Colors.orange : Colors.grey);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bgColor,
            radius: 20,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.nunito(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.nunito(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final Map<String, dynamic> activeAvatar = _avatars[_avatarIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2), // Premium sky blue header
      body: Stack(
        children: [
          // 1. Background Silhouettes
          _buildBackgroundDecor(statusBarHeight),

          // 2. Settings Cog Button (Top Right)
          Positioned(
            top: statusBarHeight + 16,
            right: 24,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Settings coming soon!",
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Title Profile (Centered at top)
          Positioned(
            top: statusBarHeight + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Profile",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            ),
          ),

          // 4. Main Scrollable Content
          Positioned(
            top: statusBarHeight + 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Avatar Circle with dynamic edit button
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          color: activeAvatar['bgColor'],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          activeAvatar['emoji'],
                          style: const TextStyle(fontSize: 84),
                        ),
                      ),
                      // Refresh / Edit Button overlay at bottom right
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _cycleAvatar,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFB020), // Yellow/orange edit badge
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sync_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name & Username
                  Text(
                    "Alex Morgan",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "@alex_morgan",
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3D Friend List Button
                  Duo3dRectButton(
                    onPressed: _showFriendsDialog,
                    faceColor: const Color(0xFFFFB020), // Gold/orange button color
                    shadowColor: const Color(0xFFD88900),
                    child: Text(
                      "Friend List",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // White Card Container for Overview & Badges
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Title
                        Text(
                          "Overview",
                          style: GoogleFonts.nunito(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Overview Row
                        Row(
                          children: [
                            // Streak Capsule
                            Expanded(
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8E9), // Soft green
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Text(
                                      "🔥",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "20 days",
                                      style: GoogleFonts.nunito(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Trophy Capsule
                            Expanded(
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FA), // Soft purple
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Text(
                                      "🏆",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "150 Trophies",
                                        style: GoogleFonts.nunito(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Badges Title
                        Text(
                          "Badges",
                          style: GoogleFonts.nunito(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Badges row of Shield shapes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            BadgeShield(
                              emoji: "🏹",
                              fillColor: const Color(0xFFFFD56B), // Golden Yellow
                              borderColor: const Color(0xFFE5A93B),
                            ),
                            BadgeShield(
                              emoji: "🪶",
                              fillColor: const Color(0xFF7A9EFF), // Sky Blue
                              borderColor: const Color(0xFF5672E5),
                            ),
                            BadgeShield(
                              emoji: "🌿",
                              fillColor: const Color(0xFF8CEEAD), // Wood Green
                              borderColor: const Color(0xFF339320),
                            ),
                            BadgeShield(
                              emoji: "🔑",
                              fillColor: const Color(0xFFBDBDBD), // Silver
                              borderColor: const Color(0xFF757575),
                            ),
                          ],
                        ),
                      ],
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

  // Floating background silhouettes for premium look
  Widget _buildBackgroundDecor(double statusBarHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 120,
            left: -15,
            child: Icon(
              Icons.code_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 320,
            right: -15,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 500,
            left: 20,
            child: Icon(
              Icons.menu_book_rounded,
              size: 70,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- CUSTOM SHIELD BADGE WIDGET ----------------

class BadgeShield extends StatelessWidget {
  final String emoji;
  final Color fillColor;
  final Color borderColor;
  final double size;

  const BadgeShield({
    super.key,
    required this.emoji,
    required this.fillColor,
    required this.borderColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.15), // Shield aspect ratio
      painter: ShieldPainter(fillColor: fillColor, borderColor: borderColor),
      child: SizedBox(
        width: size,
        height: size * 1.15,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              emoji,
              style: TextStyle(fontSize: size * 0.46),
            ),
          ),
        ),
      ),
    );
  }
}

class ShieldPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  ShieldPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Draw the shield outline shadow for 3D look
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // Build the shield path
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h * 0.58);
    // Smooth quadratic curve to bottom tip
    path.quadraticBezierTo(w, h * 0.88, w / 2, h);
    path.quadraticBezierTo(0, h * 0.88, 0, h * 0.58);
    path.close();

    // Draw shadow offset
    canvas.drawPath(path.shift(const Offset(0, 4)), shadowPaint);
    // Draw face
    canvas.drawPath(path, paint);
    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ShieldPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor || oldDelegate.borderColor != borderColor;
  }
}

// ---------------- RECTANGULAR 3D BUTTON ----------------

class Duo3dRectButton extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double borderRadius;

  const Duo3dRectButton({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    required this.onPressed,
    this.width = 185,
    this.height = 46,
    this.borderRadius = 23,
  });

  @override
  State<Duo3dRectButton> createState() => _Duo3dRectButtonState();
}

class _Duo3dRectButtonState extends State<Duo3dRectButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 6.0;
    final double translation = _isPressed ? shadowHeight : 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: widget.width,
        height: widget.height + shadowHeight,
        decoration: BoxDecoration(
          color: widget.shadowColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              top: translation,
              left: 0,
              right: 0,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.faceColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
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

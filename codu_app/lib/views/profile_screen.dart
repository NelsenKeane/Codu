import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/user_data_service.dart';
import 'settings_screen.dart';
import 'add_friend_screen.dart';
import 'friend_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _avatarIndex = 0;
  bool _showSettings = false;
  bool _showAddFriend = false;
  bool _showFriendList = false;

  String _displayName = "Codu Student";
  String _username = "@codu_student";
  int _streak = 0;
  int _trophies = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    final streak = await UserDataService().getStreak();
    final trophies = await UserDataService().getTrophies();
    final avatarIdx = await UserDataService().getAvatarIndex();

    String email = user?.email ?? "student@codu.com";
    String localUsername = email.split('@')[0];

    String finalDisplayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : localUsername.toUpperCase();

    String finalUsername = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? "@${user.displayName!.toLowerCase().replaceAll(' ', '_')}"
        : "@$localUsername";

    if (mounted) {
      setState(() {
        _streak = streak;
        _trophies = trophies;
        _avatarIndex = avatarIdx;
        _displayName = finalDisplayName;
        _username = finalUsername;
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
                            _loadProfileData();
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
                            _loadProfileData();
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

  // List of interactive avatars the user can choose from in the popup
  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '🤓', 'bgColor': const Color(0xFFFFD56B), 'name': 'Nerd Boy'},
    {'emoji': '👧', 'bgColor': const Color(0xFF8F93EA), 'name': 'Long Hair Girl'},
    {'emoji': '👦', 'bgColor': const Color(0xFFFF8B8B), 'name': 'Brandon'},
    {'emoji': '👩‍💼', 'bgColor': const Color(0xFFFFC5A5), 'name': 'Emma'},
    {'emoji': '🧒', 'bgColor': const Color(0xFF7A9EFF), 'name': 'Curly Boy'},
    {'emoji': '🧒', 'bgColor': const Color(0xFF8CEEAD), 'name': 'Bentley'},
  ];

  void _showAvatarSelectorDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Select Avatar",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                    "Choose Avatar",
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 3x2 Grid using rows
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDialogAvatarItem(0),
                          _buildDialogAvatarItem(1),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDialogAvatarItem(2),
                          _buildDialogAvatarItem(3),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDialogAvatarItem(4),
                          _buildDialogAvatarItem(5),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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

  Widget _buildDialogAvatarItem(int index) {
    final avatar = _avatars[index];
    final bool isSelected = _avatarIndex == index;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _avatarIndex = index;
        });
        await UserDataService().saveAvatarIndex(index);
        _loadProfileData();
        Navigator.of(context).pop();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: avatar['bgColor'],
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB020) : const Color(0xFFE2E4E8),
            width: isSelected ? 4.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          avatar['emoji'],
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_showSettings) {
      return SettingsView(
        onBack: () => setState(() => _showSettings = false),
      );
    }
    if (_showAddFriend) {
      return AddFriendView(
        onBack: () => setState(() => _showAddFriend = false),
      );
    }

    final Map<String, dynamic> activeAvatar = _avatars[_avatarIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2),
      body: Stack(
        children: [
          // SVG mascot background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/codu_background_pattern_mobile_soft.svg',
              fit: BoxFit.cover,
            ),
          ),

          // Main content (always visible)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header row: title + settings button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "Profile",
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                            onPressed: () => setState(() => _showSettings = true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable body content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Avatar Circle with edit button
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
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _showAvatarSelectorDialog,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFB020),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name & Username
                        Text(
                          _displayName,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _username,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Friend List Button
                        Duo3dRectButton(
                          onPressed: () => setState(() => _showFriendList = true),
                          faceColor: const Color(0xFFFFB020),
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

                        // White Card: Overview & Badges
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
                              Text(
                                "Overview",
                                style: GoogleFonts.nunito(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showStreakDialog,
                                      child: Container(
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F8E9),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          children: [
                                            const Text("🔥", style: TextStyle(fontSize: 24)),
                                            const SizedBox(width: 10),
                                            Text(
                                              "$_streak days",
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showTrophiesDialog,
                                      child: Container(
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E8FA),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          children: [
                                            const Text("🏆", style: TextStyle(fontSize: 24)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "$_trophies Trophies",
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                "Badges",
                                style: GoogleFonts.nunito(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  BadgeShield(emoji: "🏹", fillColor: const Color(0xFFFFD56B), borderColor: const Color(0xFFE5A93B)),
                                  BadgeShield(emoji: "🪶", fillColor: const Color(0xFF7A9EFF), borderColor: const Color(0xFF5672E5)),
                                  BadgeShield(emoji: "🌿", fillColor: const Color(0xFF8CEEAD), borderColor: const Color(0xFF339320)),
                                  BadgeShield(emoji: "🔑", fillColor: const Color(0xFFBDBDBD), borderColor: const Color(0xFF757575)),
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
          ),

          // Slide-down Friend List Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutQuad,
            left: 0,
            right: 0,
            top: _showFriendList ? 0 : -MediaQuery.of(context).size.height,
            height: MediaQuery.of(context).size.height,
            child: FriendListView(
              onBack: () => setState(() => _showFriendList = false),
              onAddFriend: () {
                setState(() {
                  _showFriendList = false;
                  _showAddFriend = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Floating background silhouettes for premium look
  Widget _buildBackgroundDecor(double statusBarHeight) {
    return const SizedBox.shrink();
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

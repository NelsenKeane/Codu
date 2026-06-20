import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsView extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsView({super.key, required this.onBack});

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? value,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: GoogleFonts.nunito(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2),
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/codu_background_pattern_mobile_soft.svg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Top Header (Back Chevron & Title)
          Positioned(
            top: statusBarHeight + 16,
            left: 16,
            right: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                      onPressed: onBack,
                    ),
                  ),
                ),
                Text(
                  "Settings",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),

          // 3. Scrollable Cards List
          Positioned(
            top: statusBarHeight + 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12, bottom: 120),
              child: Column(
                children: [
                  // Account Card
                  _buildSettingsCard(
                    title: "Account",
                    children: [
                      _buildSettingRow(
                        icon: Icons.person_outline_rounded,
                        title: "Personal Info",
                        iconColor: const Color(0xFF46B830),
                        iconBgColor: const Color(0xFFE8F8E9),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Color(0xFFECEFF1)),
                      _buildSettingRow(
                        icon: Icons.lock_outline_rounded,
                        title: "Privacy",
                        iconColor: const Color(0xFF46B830),
                        iconBgColor: const Color(0xFFE8F8E9),
                        onTap: () {},
                      ),
                    ],
                  ),

                  // Preference Card
                  _buildSettingsCard(
                    title: "Preference",
                    children: [
                      _buildSettingRow(
                        icon: Icons.translate_rounded,
                        title: "Language",
                        value: "English",
                        iconColor: const Color(0xFFFFB020),
                        iconBgColor: const Color(0xFFFFF7E6),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Color(0xFFECEFF1)),
                      _buildSettingRow(
                        icon: Icons.volume_up_outlined,
                        title: "Sound volume",
                        iconColor: const Color(0xFFFFB020),
                        iconBgColor: const Color(0xFFFFF7E6),
                        onTap: () {},
                      ),
                    ],
                  ),

                  // Support Card
                  _buildSettingsCard(
                    title: "Support",
                    children: [
                      _buildSettingRow(
                        icon: Icons.help_outline_rounded,
                        title: "Help center",
                        iconColor: const Color(0xFF8F93EA),
                        iconBgColor: const Color(0xFFF3E8FA),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3D Sign Out Button
                  Duo3dRectButton(
                    onPressed: () async {
                      // Perform clean log out back to LoginScreen
                      try {
                        await AuthService().signOut();
                      } catch (e) {
                        debugPrint("Error signing out: $e");
                      }
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    faceColor: const Color(0xFFFFB020), // Yellow/orange sign out button
                    shadowColor: const Color(0xFFD88900),
                    width: 280,
                    child: Text(
                      "Sign out",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
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
    return const SizedBox.shrink();
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
    required this.width,
    this.height = 50,
    this.borderRadius = 25,
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

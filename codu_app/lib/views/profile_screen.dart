import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/user_data_service.dart';
import '../services/friend_service.dart';
import '../widgets/skeleton_loader.dart';
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
    // Locally saved name takes priority over Firebase displayName
    final savedName = await UserDataService().getDisplayName();

    String email = user?.email ?? "student@codu.com";
    String localUsername = email.split('@')[0];

    String finalDisplayName;
    if (savedName != null && savedName.isNotEmpty) {
      finalDisplayName = savedName;
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      finalDisplayName = user.displayName!;
    } else {
      finalDisplayName = localUsername;
    }

    String finalUsername = "@${finalDisplayName.toLowerCase().replaceAll(' ', '_')}";

    if (mounted) {
      setState(() {
        _streak = streak;
        _trophies = trophies;
        _avatarIndex = avatarIdx;
        _displayName = finalDisplayName;
        _username = finalUsername;
        _isLoading = false;
      });
      // Sync to firestore on profile load/change
      FriendService().syncUserToFirestore().catchError((e) {
        debugPrint("Failed to sync profile: $e");
      });
    }
  }

  /// Shows a bottom-sheet style dialog for editing the display name.
  void _showEditUsernameDialog() {
    final controller = TextEditingController(text: _displayName);
    final formKey = GlobalKey<FormState>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Edit Username",
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF56CCF2).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF56CCF2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Edit Username",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF1D3557),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Choose a display name for your profile",
                      style: GoogleFonts.nunito(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Text field
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1D3557),
                      ),
                      decoration: InputDecoration(
                        hintText: "Your display name",
                        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF56CCF2)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF56CCF2), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Username cannot be empty';
                        }
                        if (val.trim().length < 2) {
                          return 'Must be at least 2 characters';
                        }
                        if (val.trim().length > 24) {
                          return 'Must be 24 characters or less';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final newName = controller.text.trim();
                                Navigator.of(ctx).pop();
                                await UserDataService().saveDisplayName(newName);
                                // Sync updated username to Firestore
                                FriendService().syncUserToFirestore().catchError((e) {
                                  debugPrint("Failed to sync username: $e");
                                });
                                if (mounted) {
                                  setState(() {
                                    _displayName = newName;
                                    _username = "@${newName.toLowerCase().replaceAll(' ', '_')}";
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF56CCF2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Save",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // List of interactive avatars the user can choose from in the popup
  final List<Map<String, dynamic>> _avatars = [
    {'svgPath': 'assets/images/Characters/Female1.svg', 'bgColor': const Color(0xFFFFD56B), 'name': 'Female 1'},
    {'svgPath': 'assets/images/Characters/Female2.svg', 'bgColor': const Color(0xFF8F93EA), 'name': 'Female 2'},
    {'svgPath': 'assets/images/Characters/Female3.svg', 'bgColor': const Color(0xFFFF8B8B), 'name': 'Female 3'},
    {'svgPath': 'assets/images/Characters/Male1.svg', 'bgColor': const Color(0xFFFFC5A5), 'name': 'Male 1'},
    {'svgPath': 'assets/images/Characters/Male2.svg', 'bgColor': const Color(0xFF7A9EFF), 'name': 'Male 2'},
    {'svgPath': 'assets/images/Characters/Male3.svg', 'bgColor': const Color(0xFF8CEEAD), 'name': 'Male 3'},
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
        final navigator = Navigator.of(context);
        setState(() {
          _avatarIndex = index;
        });
        await UserDataService().saveAvatarIndex(index);
        await _loadProfileData();
        navigator.pop();
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
        child: ClipOval(
          child: Transform.scale(
            scale: 1.2,
            child: SvgPicture.asset(
              avatar['svgPath'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildProfileSkeleton() {
    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonLoader(width: 100, height: 28),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SkeletonLoader(
                      width: 145,
                      height: 145,
                      borderRadius: BorderRadius.all(Radius.circular(72.5)),
                    ),
                    const SizedBox(height: 16),
                    const SkeletonLoader(width: 180, height: 24),
                    const SizedBox(height: 8),
                    const SkeletonLoader(width: 120, height: 16),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SkeletonLoader(width: 40, height: 20),
                                SkeletonLoader(width: 60, height: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SkeletonLoader(width: 40, height: 20),
                                SkeletonLoader(width: 60, height: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const SkeletonLoader(width: 100, height: 20),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) => const SkeletonLoader(
                        width: 65,
                        height: 65,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildProfileSkeleton();
    }
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

    // Dynamically calculate badge size and spacing to fit exactly 4 badges per row without overflow
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 80; // 16*2 margins + 24*2 padding
    final double badgeSize = ((availableWidth - 24) / 4).clamp(50.0, 95.0);
    final double spacing = ((availableWidth - (badgeSize * 4)) / 3).clamp(4.0, 16.0);

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
                              child: ClipOval(
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: SvgPicture.asset(
                                    activeAvatar['svgPath'],
                                    width: 145,
                                    height: 145,
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
                        // @username row with pencil edit button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _username,
                              style: GoogleFonts.nunito(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _showEditUsernameDialog,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
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
                                  const SizedBox(width: 12),
                                  Expanded(
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
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1.png', size: badgeSize),
                                      SizedBox(width: spacing),
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (2).png', size: badgeSize),
                                      SizedBox(width: spacing),
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (3).png', size: badgeSize),
                                      SizedBox(width: spacing),
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (4).png', size: badgeSize),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (5).png', size: badgeSize),
                                      SizedBox(width: spacing),
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (6).png', size: badgeSize),
                                      SizedBox(width: spacing),
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (7).png', size: badgeSize),
                                      SizedBox(width: spacing),
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (8).png', size: badgeSize),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      BadgeShield(imagePath: 'assets/images/Badge/Badge1 (9).png', size: badgeSize),
                                    ],
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



}

// ---------------- CUSTOM IMAGE BADGE WIDGET ----------------

class BadgeShield extends StatelessWidget {
  final String imagePath;
  final double size;

  const BadgeShield({
    super.key,
    required this.imagePath,
    this.size = 85,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/user_data_service.dart';
import '../services/friend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class PersonalInfoView extends StatefulWidget {
  final VoidCallback onBack;

  const PersonalInfoView({super.key, required this.onBack});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final savedName = await UserDataService().getDisplayName();
    
    String email = user?.email ?? "";
    String localUsername = email.isNotEmpty ? email.split('@')[0] : "";
    
    String displayName = "";
    if (savedName != null && savedName.isNotEmpty) {
      displayName = savedName;
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else {
      displayName = localUsername;
    }

    if (mounted) {
      setState(() {
        _nameController.text = displayName;
        _emailController.text = email;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newName = _nameController.text.trim();
      
      // Save locally
      await UserDataService().saveDisplayName(newName);
      
      // Update Firebase Auth user profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
      }

      // Sync to Firestore
      await FriendService().syncUserToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Personal info updated successfully!",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving personal info: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to update personal info. Please try again.",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.googleRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    setState(() {
      _isSaving = true;
    });

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Delete /users/{uid} document
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.delete(userDocRef);

      // 2. Delete /users/{uid}/courses subcollection docs
      final List<String> subjects = ['python', 'c++', 'javascript', 'java'];
      for (final docId in subjects) {
        batch.delete(userDocRef.collection('courses').doc(docId));
        
        // 3. Delete root level /courses/{docId}/users/{uid}
        batch.delete(FirebaseFirestore.instance.collection('courses').doc(docId).collection('users').doc(uid));

        // 4. Delete root level /courses/{uid}_{docId}
        batch.delete(FirebaseFirestore.instance.collection('courses').doc('${uid}_$docId'));
      }

      // 5. Clean up friends connections
      final friendsSnap = await userDocRef.collection('friends').get();
      for (var friendDoc in friendsSnap.docs) {
        final friendUid = friendDoc.id;
        // Delete this user from friend's list
        batch.delete(FirebaseFirestore.instance.collection('users').doc(friendUid).collection('friends').doc(uid));
        // Delete friend from this user's list
        batch.delete(userDocRef.collection('friends').doc(friendUid));
      }

      // 6. Clean up requests connections
      final requestsSnap = await userDocRef.collection('requests').get();
      for (var reqDoc in requestsSnap.docs) {
        final targetUid = reqDoc.id;
        // Delete this user from target's requests
        batch.delete(FirebaseFirestore.instance.collection('users').doc(targetUid).collection('requests').doc(uid));
        // Delete request from this user's requests
        batch.delete(userDocRef.collection('requests').doc(targetUid));
      }

      // Commit the batch deletion
      await batch.commit();

      // 2. Delete Auth User
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Account permanently deleted.",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.googleRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Exception deleting account: $e");
      if (e.code == 'requires-recent-login') {
        // Restore Firestore document since deletion failed/was aborted by security rule
        try {
          await FriendService().syncUserToFirestore();
        } catch (_) {}

        // Auto sign out
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "For security, please log in again to delete your account.",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.googleRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to delete account: ${e.message}",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.googleRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "An error occurred. Please try again.",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.googleRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _confirmDeleteAccount() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Confirm Delete",
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
                    "Delete Account",
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all progress.",
                    style: GoogleFonts.nunito(
                      color: AppColors.textGrey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.nunito(
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteAccount();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.googleRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Delete",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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
        );
      },
    );
  }

  Widget _buildTextFieldCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
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
            label,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            validator: validator,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: readOnly ? AppColors.textGrey : AppColors.textDark,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: readOnly ? AppColors.textGrey : const Color(0xFF56CCF2),
              ),
              suffixIcon: readOnly
                  ? const Icon(Icons.lock_outline_rounded, color: AppColors.textGrey, size: 20)
                  : null,
              filled: true,
              fillColor: readOnly ? const Color(0xFFF2F4F7) : const Color(0xFFF9FAFB),
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
          ),
        ],
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

          // Header
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
                      onPressed: widget.onBack,
                    ),
                  ),
                ),
                Text(
                  "Personal Info",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Positioned(
            top: statusBarHeight + 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12, bottom: 120),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextFieldCard(
                            label: "Display Name",
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Name cannot be empty";
                              }
                              if (val.trim().length < 2) {
                                return "Must be at least 2 characters";
                              }
                              return null;
                            },
                          ),
                          _buildTextFieldCard(
                            label: "Email Address",
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            readOnly: true,
                          ),
                          const SizedBox(height: 32),
                          _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Column(
                                  children: [
                                    Duo3dRectButton(
                                      onPressed: _saveChanges,
                                      faceColor: const Color(0xFFFFB020),
                                      shadowColor: const Color(0xFFD88900),
                                      width: 280,
                                      child: Text(
                                        "Save Changes",
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Duo3dRectButton(
                                      onPressed: _confirmDeleteAccount,
                                      faceColor: AppColors.googleRed,
                                      shadowColor: const Color(0xFF7A0810),
                                      width: 280,
                                      child: Text(
                                        "Delete Account",
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
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
        ],
      ),
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

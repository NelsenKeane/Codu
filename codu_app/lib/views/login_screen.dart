import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/duo_3d_button.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignIn = true; // Tab state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _usernameController = TextEditingController(); // Sign-in email
  final TextEditingController _emailController = TextEditingController();    // Sign-up email
  final TextEditingController _signUpUsernameController = TextEditingController(); // Sign-up username
  final TextEditingController _passwordController = TextEditingController(); // Password
  final TextEditingController _confirmPasswordController = TextEditingController(); // Confirm password

  // Focus nodes to track active states
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _signUpUsernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Rebuild when focus changes to update active borders
    _usernameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _signUpUsernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _signUpUsernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _signUpUsernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppColors.googleRed : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address.");
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Please enter a valid email address.");
      return;
    }
    if (password.isEmpty) {
      _showSnackBar("Please enter your password.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().signIn(email: email, password: password);
      if (mounted) {
        _showSnackBar("Logged in successfully!", isError: false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This user account has been disabled.";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "Invalid login credentials.";
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      if (mounted) {
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("An unexpected error occurred: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    final username = _signUpUsernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address.");
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Please enter a valid email address.");
      return;
    }
    if (username.isEmpty) {
      _showSnackBar("Please enter a username.");
      return;
    }
    if (password.isEmpty) {
      _showSnackBar("Please create a password.");
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters long.");
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().signUp(
        email: email,
        password: password,
        fullName: username,
      );
      if (mounted) {
        _showSnackBar("Verification email sent!", isError: false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        errorMessage = "The email is already registered.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is invalid.";
      } else if (e.code == 'weak-password') {
        errorMessage = "The password provided is too weak.";
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      if (mounted) {
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("An unexpected error occurred: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.skyBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Header Area (Sky Blue background with mascot and speech bubble)
                  _buildHeader(statusBarHeight),

                  // Tab Bar Area
                  _buildTabs(),

                  // Main Card Container (Light Blue background)
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        // Logo
                        Image.asset(
                          'assets/images/codu_logo.png',
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        
                        // Form Fields & Action Buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isSignIn ? _buildSignInForm() : _buildSignUpForm(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.skyBlue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Please wait...",
                            style: GoogleFonts.nunito(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
              _buildCodeButton(),
              const SizedBox(height: 8),
              // Mascot and Speech Bubble
              _buildMascotHeader(),
            ],
          ),
        ),
      ],
    );
  }

  // Code Icon Button Widget
  Widget _buildCodeButton() {
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
                      _isSignIn ? "Welcome Back !" : "Lets Get Started !",
                      style: GoogleFonts.nunito(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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

  // Custom Tabs Widget
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // LOG IN Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSignIn) {
                  setState(() {
                    _isSignIn = true;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSignIn ? Colors.white : AppColors.tabInactiveBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "LOG IN",
                  style: GoogleFonts.nunito(
                    color: _isSignIn ? Colors.black : Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // REGISTER Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSignIn) {
                  setState(() {
                    _isSignIn = false;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isSignIn ? Colors.white : AppColors.tabInactiveBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "REGISTER",
                  style: GoogleFonts.nunito(
                    color: !_isSignIn ? Colors.black : Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sign In Form View
  Widget _buildSignInForm() {
    return Column(
      key: const ValueKey('SignInForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // White input container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                controller: _usernameController,
                hintText: "Email Address",
                prefixIcon: Icons.person_outline,
                focusNode: _usernameFocus,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                focusNode: _passwordFocus,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // Action
                  },
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.nunito(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 3D LOG IN Button
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: _handleSignIn,
          child: Text(
            "LOG IN",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildDivider(),
        const SizedBox(height: 24),
        _buildSocialButtons(),
      ],
    );
  }

  // Sign Up Form View
  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('SignUpForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // White input container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                controller: _emailController,
                hintText: "Email Address",
                prefixIcon: Icons.person_outline,
                focusNode: _emailFocus,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _signUpUsernameController,
                hintText: "Username",
                prefixIcon: Icons.person_outline,
                focusNode: _signUpUsernameFocus,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                focusNode: _passwordFocus,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isConfirmPasswordVisible,
                focusNode: _confirmPasswordFocus,
                onToggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 3D REGISTER Button
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: _handleSignUp,
          child: Text(
            "REGISTER",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildDivider(),
        const SizedBox(height: 24),
        _buildSocialButtons(),
      ],
    );
  }

  // Reusable Text Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      focusNode: focusNode,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textGrey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: AppColors.inputBackgroundLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 12.0),
                child: Icon(
                   prefixIcon,
                  color: AppColors.textGrey,
                  size: 20,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.yellow,
            width: 1.5,
          ),
        ),
        suffixIcon: isPassword
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textGrey,
                  ),
                  onPressed: onToggleVisibility,
                ),
              )
            : null,
      ),
    );
  }

  // Divider row ("Login With" / "Sign Up With")
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFFD4E3EF),
            thickness: 1.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _isSignIn ? "Login With" : "Sign Up With",
            style: GoogleFonts.nunito(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFFD4E3EF),
            thickness: 1.5,
          ),
        ),
      ],
    );
  }

  // Social buttons row
  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Button
        _buildSocialIconCard(
          icon: Image.network(
            'https://developers.google.com/static/identity/images/g-logo.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.g_mobiledata_rounded,
              color: AppColors.googleRed,
              size: 28,
            ),
          ),
          onTap: () {
            // Action
          },
        ),
        const SizedBox(width: 16),
        // Facebook Button
        _buildSocialIconCard(
          icon: Text(
            'f',
            style: GoogleFonts.nunito(
              color: const Color(0xFF1877F2),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          onTap: () {
            // Action
          },
        ),
      ],
    );
  }

  // Circular white card for social buttons
  Widget _buildSocialIconCard({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 50,
      height: 53,
      child: Duo3dButton(
        height: 50,
        shadowHeight: 3,
        borderRadius: 25,
        faceColor: Colors.white,
        shadowColor: const Color(0xFFD4E3EF),
        onPressed: onTap,
        child: icon,
      ),
    );
  }
}

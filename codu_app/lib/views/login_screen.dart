import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/duo_3d_button.dart';
import '../widgets/otp_input.dart';
import 'main_screen.dart';

enum LoginViewState {
  login,
  forgotPassword,
  checkEmail,
  register,
  verifyEmail,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginViewState _viewState = LoginViewState.login;
  bool _isPasswordVisible = false;

  // Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerUsernameController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _registerConfirmPasswordController = TextEditingController();
  
  final TextEditingController _forgotEmailController = TextEditingController();
  
  String _otpCode = "";

  // Focus nodes
  final FocusNode _loginEmailFocus = FocusNode();
  final FocusNode _loginPasswordFocus = FocusNode();
  final FocusNode _registerEmailFocus = FocusNode();
  final FocusNode _registerUsernameFocus = FocusNode();
  final FocusNode _registerPasswordFocus = FocusNode();
  final FocusNode _registerConfirmPasswordFocus = FocusNode();
  final FocusNode _forgotEmailFocus = FocusNode();

  // Timer fields for OTP Resend
  Timer? _resendTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // Add focus listeners to rebuild for focus states
    _loginEmailFocus.addListener(_onFocusChange);
    _loginPasswordFocus.addListener(_onFocusChange);
    _registerEmailFocus.addListener(_onFocusChange);
    _registerUsernameFocus.addListener(_onFocusChange);
    _registerPasswordFocus.addListener(_onFocusChange);
    _registerConfirmPasswordFocus.addListener(_onFocusChange);
    _forgotEmailFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    // Clean up controllers
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _forgotEmailController.dispose();

    // Clean up focus nodes
    _loginEmailFocus.removeListener(_onFocusChange);
    _loginPasswordFocus.removeListener(_onFocusChange);
    _registerEmailFocus.removeListener(_onFocusChange);
    _registerUsernameFocus.removeListener(_onFocusChange);
    _registerPasswordFocus.removeListener(_onFocusChange);
    _registerConfirmPasswordFocus.removeListener(_onFocusChange);
    _forgotEmailFocus.removeListener(_onFocusChange);

    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    _registerEmailFocus.dispose();
    _registerUsernameFocus.dispose();
    _registerPasswordFocus.dispose();
    _registerConfirmPasswordFocus.dispose();
    _forgotEmailFocus.dispose();

    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _resendTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.skyBlue,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Area (Sky Blue background with mascot and speech bubble)
            _buildHeader(statusBarHeight),

            // Tab Bar Area (Only visible on login and register states)
            if (_viewState == LoginViewState.login || _viewState == LoginViewState.register)
              _buildTabs()
            else
              const SizedBox(height: 20),

            // Main Card Container (White background to match the mockups)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
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
                      duration: const Duration(milliseconds: 250),
                      child: _buildFormContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Determines which form content to build based on view state
  Widget _buildFormContent() {
    switch (_viewState) {
      case LoginViewState.login:
        return _buildSignInForm();
      case LoginViewState.register:
        return _buildSignUpForm();
      case LoginViewState.forgotPassword:
        return _buildForgotPasswordForm();
      case LoginViewState.checkEmail:
        return _buildCheckEmailForm();
      case LoginViewState.verifyEmail:
        return _buildVerifyEmailForm();
    }
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

  // Mascot + Speech Bubble Widget with dynamic text based on view state
  Widget _buildMascotHeader() {
    String bubbleText = "Welcome Back !";
    switch (_viewState) {
      case LoginViewState.login:
        bubbleText = "Welcome Back !";
        break;
      case LoginViewState.forgotPassword:
        bubbleText = "No Problem !\nLet's Get You Back In !";
        break;
      case LoginViewState.checkEmail:
        bubbleText = "Email Sent !\nCheck Your Inbox !";
        break;
      case LoginViewState.register:
        bubbleText = "Lets Get Started !";
        break;
      case LoginViewState.verifyEmail:
        bubbleText = "Almost Done !\nCheck Your Inbox !";
        break;
    }

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
                      bubbleText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
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

  // Custom Tabs Widget
  Widget _buildTabs() {
    final bool isSignIn = _viewState == LoginViewState.login;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // LOG IN Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSignIn) {
                  setState(() {
                    _viewState = LoginViewState.login;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSignIn ? Colors.white : AppColors.tabInactiveBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "LOG IN",
                  style: GoogleFonts.nunito(
                    color: isSignIn ? Colors.black : Colors.white.withValues(alpha: 0.8),
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
                if (isSignIn) {
                  setState(() {
                    _viewState = LoginViewState.register;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !isSignIn ? Colors.white : AppColors.tabInactiveBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "REGISTER",
                  style: GoogleFonts.nunito(
                    color: !isSignIn ? Colors.black : Colors.white.withValues(alpha: 0.8),
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
        _buildInputField(
          controller: _loginEmailController,
          hintText: "Email Address",
          prefixIcon: Icons.person_outline,
          focusNode: _loginEmailFocus,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _loginPasswordController,
          hintText: "Password",
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          focusNode: _loginPasswordFocus,
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
              setState(() {
                _viewState = LoginViewState.forgotPassword;
              });
            },
            child: Text(
              "Forgot Password?",
              style: GoogleFonts.nunito(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 3D LOG IN Button
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
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
        _buildDivider("Login With"),
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
        _buildInputField(
          controller: _registerEmailController,
          hintText: "Email Address",
          prefixIcon: Icons.email_outlined,
          focusNode: _registerEmailFocus,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _registerUsernameController,
          hintText: "Username",
          prefixIcon: Icons.person_outline,
          focusNode: _registerUsernameFocus,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _registerPasswordController,
          hintText: "Password",
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          focusNode: _registerPasswordFocus,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _registerConfirmPasswordController,
          hintText: "Confirm Password",
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          focusNode: _registerConfirmPasswordFocus,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 24),
        // 3D REGISTER Button (matching yellow from mockup)
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: () {
            setState(() {
              _viewState = LoginViewState.verifyEmail;
            });
            _startResendTimer();
          },
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
        _buildDivider("Sign Up With"),
        const SizedBox(height: 24),
        _buildSocialButtons(),
      ],
    );
  }

  // Forgot Password Form View
  Widget _buildForgotPasswordForm() {
    return Column(
      key: const ValueKey('ForgotPasswordForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            "Forgot Password",
            style: GoogleFonts.nunito(
              color: AppColors.blue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Enter Your Email Address and We'll\nSend You a Link To Reset Your Password",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _forgotEmailController,
          hintText: "Email Address",
          prefixIcon: Icons.email_outlined,
          focusNode: _forgotEmailFocus,
        ),
        const SizedBox(height: 24),
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: () {
            setState(() {
              _viewState = LoginViewState.checkEmail;
            });
          },
          child: Text(
            "SEND LINK",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Remember Password? ",
              style: GoogleFonts.nunito(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _viewState = LoginViewState.login;
                });
              },
              child: Text(
                "Go Back",
                style: GoogleFonts.nunito(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Check Email / Email Sent View
  Widget _buildCheckEmailForm() {
    return Column(
      key: const ValueKey('CheckEmailForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            "Check Your Email !",
            style: GoogleFonts.nunito(
              color: AppColors.blue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.mail_rounded,
                  size: 100,
                  color: Colors.grey[400],
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: () {
            setState(() {
              _viewState = LoginViewState.login;
            });
          },
          child: Text(
            "BACK TO LOGIN",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // Verify Email / OTP Form View
  Widget _buildVerifyEmailForm() {
    final String email = _registerEmailController.text.trim().isNotEmpty
        ? _registerEmailController.text.trim()
        : "codu@gmail.com";
        
    return Column(
      key: const ValueKey('VerifyEmailForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            "Verify Your Email",
            style: GoogleFonts.nunito(
              color: AppColors.blue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "We've Sent A 6-Digit Code to:",
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Center(
          child: Text(
            email,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 24),
        OtpInput(
          onChanged: (code) {
            _otpCode = code;
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: _canResend
              ? GestureDetector(
                  onTap: _startResendTimer,
                  child: Text(
                    "Resend Code",
                    style: GoogleFonts.nunito(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: "Didn't Receive Email? Resend in "),
                      TextSpan(
                        text: "${_secondsRemaining}s",
                        style: GoogleFonts.nunito(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        Duo3dButton(
          faceColor: AppColors.yellow,
          shadowColor: AppColors.yellowShadow,
          borderRadius: 25,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
          child: Text(
            "VERIFY",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.yellow,
            width: 2.0,
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

  // Divider row
  Widget _buildDivider(String text) {
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
            text,
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

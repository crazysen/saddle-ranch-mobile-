import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/apple_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isSignUp = false;

  // Login Form Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController(text: 'customer@saddleranch.ph');
  final _loginPasswordController = TextEditingController(text: 'customer123');
  bool _loginObscurePassword = true;
  bool _rememberMe = true;

  // SignUp Form Controllers
  final _signUpFormKey = GlobalKey<FormState>();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  bool _signUpObscurePassword = true;
  bool _signUpObscureConfirmPassword = true;

  static const Color _primaryOrange = Color(0xFFFF5500);
  static const Color _inputBackground = Color(0xFFF2F2F7);
  static const Color _mutedText = Color(0xFF71717A);
  static const Color _darkText = Color(0xFF18181B);
  static const Color _cardBorder = Color(0xFFE5E5EA);

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode(bool signUp) {
    AppleTheme.hapticFeedback();
    setState(() {
      _isSignUp = signUp;
    });
  }

  Future<void> _handleLoginSubmit() async {
    AppleTheme.hapticFeedback();
    if (!_loginFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithEmail(
      email: _loginEmailController.text,
      password: _loginPasswordController.text,
    );

    if (!mounted) return;
    if (!success && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppleColors.danger,
        ),
      );
    }
  }

  Future<void> _handleSignUpSubmit() async {
    AppleTheme.hapticFeedback();
    if (!_signUpFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _signUpNameController.text,
      email: _signUpEmailController.text,
      password: _signUpPasswordController.text,
      passwordConfirmation: _signUpConfirmPasswordController.text,
      phone: _signUpPhoneController.text,
    );

    if (!mounted) return;
    if (!success && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppleColors.danger,
        ),
      );
    }
  }

  void _fillCustomerDemo() {
    AppleTheme.hapticFeedback();
    setState(() {
      _loginEmailController.text = 'customer@saddleranch.ph';
      _loginPasswordController.text = 'customer123';
    });
  }

  void _fillDevAccess() {
    AppleTheme.hapticFeedback();
    setState(() {
      _loginEmailController.text = 'dev@saddleranch.ph';
      _loginPasswordController.text = 'devpass123';
    });
  }

  // Login View Widget Tree
  Widget _buildLoginForm(AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Block
          Center(
            child: Text(
              'Login',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't Have An Account? ",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _mutedText,
                ),
              ),
              GestureDetector(
                onTap: () => _toggleAuthMode(true),
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (auth.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppleColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppleColors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                auth.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppleColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Email Input Field
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'customer@saddleranch.ph',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.mail, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password Input Field
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _loginObscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.lock, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: _mutedText,
                ),
                onPressed: () {
                  AppleTheme.hapticFeedback();
                  setState(() => _loginObscurePassword = !_loginObscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Toggles Row (Remember Me & Forgot Password)
          Row(
            children: [
              SizedBox(
                height: 22,
                width: 22,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: _primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: _cardBorder, width: 1.5),
                  onChanged: (val) {
                    setState(() => _rememberMe = val ?? true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember Me',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _darkText,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => AppleTheme.hapticFeedback(),
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Primary Action Button (Login Pill)
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: auth.busy ? null : _handleLoginSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: auth.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Login',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Centered Divider
          Row(
            children: [
              const Expanded(child: Divider(color: _cardBorder, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Or Continue With',
                  style: GoogleFonts.inter(
                    color: _darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _cardBorder, thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),

          // Social Button ("Continue with Google")
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: auth.busy
                  ? null
                  : () async {
                      AppleTheme.hapticFeedback();
                      await context.read<AuthProvider>().signInWithGoogle();
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _cardBorder, width: 1.2),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                    width: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      'https://pngimg.com/uploads/google/google_PNG19635.png',
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.g_mobiledata,
                        size: 26,
                        color: _darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      color: _darkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick-Fill Demo Access Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _inputBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _fillCustomerDemo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.user, size: 14, color: _primaryOrange),
                        const SizedBox(width: 6),
                        Text(
                          'Customer Demo',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _fillDevAccess,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.code2, size: 14, color: _primaryOrange),
                        const SizedBox(width: 6),
                        Text(
                          'Dev Access',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Create Account View Widget Tree
  Widget _buildSignUpForm(AuthProvider auth) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        key: const ValueKey('signup_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Back Navigation Row
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: _darkText, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _toggleAuthMode(false),
              ),
              const SizedBox(width: 10),
              Text(
                'Create Account',
                style: GoogleFonts.domine(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Join Saddle Ranch to order sizzling favorites, save your details, and unlock rewards.',
            style: GoogleFonts.inter(
              color: _mutedText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          if (auth.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppleColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppleColors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                auth.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppleColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Full Name Input
          TextFormField(
            controller: _signUpNameController,
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Juan Dela Cruz',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.user, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Email Input
          TextFormField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'name@example.com',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.mail, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Phone Input (Optional)
          TextFormField(
            controller: _signUpPhoneController,
            keyboardType: TextInputType.phone,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: '09171234567 (Optional)',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.phone, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Password Input
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: _signUpObscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Create a password (min 6 chars)',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.lock, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpObscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: _mutedText,
                ),
                onPressed: () {
                  AppleTheme.hapticFeedback();
                  setState(() => _signUpObscurePassword = !_signUpObscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please create a password.';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirm Password Input
          TextFormField(
            controller: _signUpConfirmPasswordController,
            obscureText: _signUpObscureConfirmPassword,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(color: _darkText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              hintStyle: GoogleFonts.inter(color: _mutedText, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.lock, size: 18, color: _mutedText),
              fillColor: _inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpObscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: _mutedText,
                ),
                onPressed: () {
                  AppleTheme.hapticFeedback();
                  setState(() => _signUpObscureConfirmPassword = !_signUpObscureConfirmPassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password.';
              }
              if (value != _signUpPasswordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Primary Orange "Create Account" CTA Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: auth.busy ? null : _handleSignUpSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: auth.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),

          // Bottom Link Back To Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _mutedText,
                ),
              ),
              GestureDetector(
                onTap: () => _toggleAuthMode(false),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mediaQuery = MediaQuery.of(context);

    // Dynamic Hero Header Height: ~40% for Login, ~18% for SignUp
    final heroHeight = _isSignUp ? mediaQuery.size.height * 0.18 : mediaQuery.size.height * 0.40;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Dynamic Hero Header (AnimatedContainer)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.fastOutSlowIn,
              height: heroHeight + 32, // Extra overlap margin
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Flame-grilled steaks background image
                  Image.asset(
                    'assets/images/frame_005.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2C1400), _primaryOrange],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Dark Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top-Left SR Emblem Badge (Only visible in Login mode)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                    top: mediaQuery.padding.top + 12,
                    left: 20,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isSignUp ? 0.0 : 1.0,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'S R',
                              style: GoogleFonts.domine(
                                color: _darkText,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Saddle Ranch',
                              style: GoogleFonts.inter(
                                color: _mutedText,
                                fontSize: 7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Hero Title Text Overlay (Fades out when Morphing to SignUp)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 48,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isSignUp ? 0.0 : 1.0,
                      child: Text(
                        'Log in to stay on top\nof your sizzling orders.',
                        style: GoogleFonts.domine(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Colors.white,
                          height: 1.25,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Morphing White Card Container (AnimatedSize + AnimatedSwitcher)
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 450),
                curve: Curves.fastOutSlowIn,
                padding: EdgeInsets.only(top: heroHeight),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.fastOutSlowIn,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final isSignUpChild = child.key == const ValueKey('signup_form');
                          final beginOffset = isSignUpChild ? const Offset(0.25, 0.0) : const Offset(-0.25, 0.0);
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: beginOffset,
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _isSignUp ? _buildSignUpForm(auth) : _buildLoginForm(auth),
                      ),
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
}

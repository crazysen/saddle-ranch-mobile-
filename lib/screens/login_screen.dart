import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/apple_theme.dart';

enum AuthScreenMode { welcome, login, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthScreenMode _mode = AuthScreenMode.login;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'customer@saddleranch.ph');
  final _passwordController = TextEditingController(text: 'customer123');
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    AppleTheme.hapticFeedback();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success = false;

    if (_mode == AuthScreenMode.signUp) {
      success = await auth.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );
    } else {
      success = await auth.loginWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

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

  Widget _buildGoogleButton() {
    final auth = context.watch<AuthProvider>();
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: auth.busy
            ? null
            : () async {
                AppleTheme.hapticFeedback();
                await context.read<AuthProvider>().signInWithGoogle();
              },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppleColors.cardBorder, width: 1.2),
          backgroundColor: AppleColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
                  color: AppleColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                color: AppleColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    String heroTitle = 'Log in to stay on top of your sizzling orders.';
    if (_mode == AuthScreenMode.welcome) {
      heroTitle = 'Experience the Sizzling Ranch Customer App.';
    } else if (_mode == AuthScreenMode.signUp) {
      heroTitle = 'Create Your Account & Order Sizzling Delights.';
    }

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      body: Stack(
        children: [
          // Top Hero Area: Hero Frame Image Background (frame_005.png) with text overlay
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/frame_005.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3F2000), AppleColors.primaryAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Overlay Headline text matched with screenshot design
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              heroTitle,
                              style: GoogleFonts.domine(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 5,
                  child: SizedBox.expand(),
                ),
              ],
            ),
          ),

          // Bottom Area: Foodpanda / Asana Style Sheet Container (32px Top Radius)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppleColors.pureWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle bar pill
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppleColors.cardBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

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

                        // Mode 1: Welcome / Onboarding Card
                        if (_mode == AuthScreenMode.welcome) ...[
                          Center(
                            child: Text(
                              'SADDLE RANCH',
                              style: GoogleFonts.domine(
                                color: AppleColors.primaryAccent,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              "Let's Get You Set Up for Success",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.domine(
                                color: AppleColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Order sizzling steaks, pork sisig, and drinks seamlessly for dine-in or delivery.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppleColors.mutedText,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                AppleTheme.hapticFeedback();
                                setState(() => _mode = AuthScreenMode.login);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppleColors.primaryAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGoogleButton(),
                        ],

                        // Mode 2: Login Mode
                        if (_mode == AuthScreenMode.login) ...[
                          Center(
                            child: Text(
                              'Login',
                              style: GoogleFonts.domine(
                                color: AppleColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
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
                                  color: AppleColors.mutedText,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  AppleTheme.hapticFeedback();
                                  setState(() => _mode = AuthScreenMode.signUp);
                                },
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.inter(
                                    color: AppleColors.primaryAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: GoogleFonts.inter(color: AppleColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              prefixIcon: const Icon(LucideIcons.mail, size: 18),
                              fillColor: AppleColors.cardSurface,
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
                          const SizedBox(height: 12),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: GoogleFonts.inter(color: AppleColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(LucideIcons.lock, size: 18),
                              fillColor: AppleColors.cardSurface,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 18,
                                  color: AppleColors.mutedText,
                                ),
                                onPressed: () {
                                  AppleTheme.hapticFeedback();
                                  setState(() => _obscurePassword = !_obscurePassword);
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
                          const SizedBox(height: 12),

                          // Options Row: Remember Me & Forgot Password
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppleColors.primaryAccent,
                                  onChanged: (val) {
                                    setState(() => _rememberMe = val ?? true);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember Me',
                                style: GoogleFonts.inter(
                                  color: AppleColors.mutedText,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    color: AppleColors.primaryAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Login CTA Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: auth.busy ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppleColors.primaryAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider Or Continue With
                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppleColors.cardBorder)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Or Continue With',
                                  style: GoogleFonts.inter(
                                    color: AppleColors.mutedText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: AppleColors.cardBorder)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildGoogleButton(),
                        ],

                        // Mode 3: Sign Up Mode
                        if (_mode == AuthScreenMode.signUp) ...[
                          Center(
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.domine(
                                color: AppleColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already Have An Account? ",
                                style: GoogleFonts.inter(
                                  color: AppleColors.mutedText,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  AppleTheme.hapticFeedback();
                                  setState(() => _mode = AuthScreenMode.login);
                                },
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    color: AppleColors.primaryAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Full Name Input
                          TextFormField(
                            controller: _nameController,
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.inter(color: AppleColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: const Icon(LucideIcons.user, size: 18),
                              fillColor: AppleColors.cardSurface,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (value) {
                              if (_mode == AuthScreenMode.signUp && (value == null || value.trim().isEmpty)) {
                                return 'Please enter your full name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: GoogleFonts.inter(color: AppleColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              prefixIcon: const Icon(LucideIcons.mail, size: 18),
                              fillColor: AppleColors.cardSurface,
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
                          const SizedBox(height: 12),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: GoogleFonts.inter(color: AppleColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(LucideIcons.lock, size: 18),
                              fillColor: AppleColors.cardSurface,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 18,
                                  color: AppleColors.mutedText,
                                ),
                                onPressed: () {
                                  AppleTheme.hapticFeedback();
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password.';
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
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: GoogleFonts.inter(color: AppleColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              prefixIcon: const Icon(LucideIcons.lock, size: 18),
                              fillColor: AppleColors.cardSurface,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 18,
                                  color: AppleColors.mutedText,
                                ),
                                onPressed: () {
                                  AppleTheme.hapticFeedback();
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (_mode == AuthScreenMode.signUp) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password.';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Sign Up CTA Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: auth.busy ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppleColors.primaryAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                                      'Sign Up',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider Or Continue With
                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppleColors.cardBorder)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Or Continue With',
                                  style: GoogleFonts.inter(
                                    color: AppleColors.mutedText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: AppleColors.cardBorder)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildGoogleButton(),
                        ],
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
}

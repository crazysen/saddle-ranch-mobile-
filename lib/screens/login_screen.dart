import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/apple_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'customer@saddleranch.ph');
  final _passwordController = TextEditingController(text: 'customer123');

  bool _obscurePassword = true;
  bool _rememberMe = true;

  static const Color _primaryOrange = Color(0xFFFF5500);
  static const Color _inputBackground = Color(0xFFF2F2F7);
  static const Color _mutedText = Color(0xFF71717A);
  static const Color _darkText = Color(0xFF18181B);
  static const Color _cardBorder = Color(0xFFE5E5EA);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    AppleTheme.hapticFeedback();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
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
      _emailController.text = 'customer@saddleranch.ph';
      _passwordController.text = 'customer123';
    });
  }

  void _fillDevAccess() {
    AppleTheme.hapticFeedback();
    setState(() {
      _emailController.text = 'dev@saddleranch.ph';
      _passwordController.text = 'devpass123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mediaQuery = MediaQuery.of(context);
    final heroHeight = mediaQuery.size.height * 0.42;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Top Hero Image Header (Top 42% Viewport Height)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + 32, // Extra overlap margin
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Flame-Grilled Steaks Image
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

                // Dark Bottom Gradient Scrim Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top-Left SR Saddle Ranch Circular Emblem Badge
                Positioned(
                  top: mediaQuery.padding.top + 16,
                  left: 20,
                  child: Container(
                    width: 56,
                    height: 56,
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
                            fontSize: 16,
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

                // Hero Title Text positioned in bottom-left above the card curve
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 48,
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
              ],
            ),
          ),

          // 2. Overlapping White Card (Bottom Sheet Container)
          Positioned.fill(
            top: heroHeight,
            child: Container(
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
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
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
                              onTap: () {
                                AppleTheme.hapticFeedback();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
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
                          controller: _emailController,
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
                          controller: _passwordController,
                          obscureText: _obscurePassword,
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
                                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 18,
                                color: _mutedText,
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
                              onTap: () {
                                AppleTheme.hapticFeedback();
                              },
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
                            onPressed: auth.busy ? null : _handleLogin,
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

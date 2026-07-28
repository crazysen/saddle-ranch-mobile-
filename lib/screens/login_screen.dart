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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fillCustomerDemo() async {
    AppleTheme.hapticFeedback();
    setState(() {
      _emailController.text = 'customer@saddleranch.ph';
      _passwordController.text = 'customer123';
    });
    await context.read<AuthProvider>().loginAsDemo(
      email: 'customer@saddleranch.ph',
      fullName: 'Juan Dela Cruz',
      phone: '09171234567',
    );
  }

  Future<void> _fillDeveloperDemo() async {
    AppleTheme.hapticFeedback();
    setState(() {
      _emailController.text = 'dev@saddleranch.ph';
      _passwordController.text = 'devpass123';
    });
    await context.read<AuthProvider>().loginAsDemo(
      email: 'dev@saddleranch.ph',
      fullName: 'Dev Tester',
      phone: '09998887766',
    );
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Brand Header / Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppleColors.primaryAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppleColors.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.domine(
                    color: AppleColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to order sizzling steaks, track table orders, and access exclusive offers.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppleColors.mutedText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
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

                // Email field
                Text(
                  'Email Address',
                  style: GoogleFonts.inter(
                    color: AppleColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: GoogleFonts.inter(color: AppleColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(LucideIcons.mail, size: 20),
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
                const SizedBox(height: 18),

                // Password field
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                    color: AppleColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(color: AppleColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20,
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
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.busy ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppleColors.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider / Google Sign-in Option
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppleColors.cardBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppleColors.cardBorder)),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: auth.busy
                        ? null
                        : () async {
                            AppleTheme.hapticFeedback();
                            await context.read<AuthProvider>().signInWithGoogle();
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppleColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://pngimg.com/uploads/google/google_PNG19635.png',
                          height: 22,
                          width: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.g_mobiledata,
                            size: 28,
                            color: AppleColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            color: AppleColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Apple-styled Demo Account Auto-Fill Strip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppleColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppleColors.cardBorder),
                    boxShadow: AppleColors.ambientShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 16, color: AppleColors.primaryAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Demo Access',
                            style: GoogleFonts.domine(
                              color: AppleColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _fillCustomerDemo,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppleColors.pureWhite,
                                foregroundColor: AppleColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                side: const BorderSide(color: AppleColors.cardBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(LucideIcons.user, size: 15, color: AppleColors.primaryAccent),
                              label: Text(
                                'Customer Demo',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _fillDeveloperDemo,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppleColors.pureWhite,
                                foregroundColor: AppleColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                side: const BorderSide(color: AppleColors.cardBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(LucideIcons.code2, size: 15, color: AppleColors.primaryAccent),
                              label: Text(
                                'Developer Access',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Register Navigation Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(
                        color: AppleColors.mutedText,
                        fontSize: 14,
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
                          color: AppleColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_session_provider.dart';
import '../theme/apple_theme.dart';
import '../utils/cavite_locations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Sign Up Controllers
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _loginObscurePassword = true;
  bool _signUpObscurePassword = true;
  bool _signUpObscureConfirmPassword = true;
  bool _rememberMe = true;

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

  void _switchToSignUp() {
    AppleTheme.hapticFeedback();
    setState(() => _isSignUp = true);
  }

  void _switchToLogin() {
    AppleTheme.hapticFeedback();
    setState(() => _isSignUp = false);
  }

  Future<void> _handleLoginSubmit() async {
    AppleTheme.hapticFeedback();
    if (!_loginFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithEmail(
      email: _loginEmailController.text.trim(),
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
      name: _signUpNameController.text.trim(),
      email: _signUpEmailController.text.trim(),
      password: _signUpPasswordController.text,
      passwordConfirmation: _signUpConfirmPasswordController.text,
      phone: _signUpPhoneController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      _showOptionalLocationSheet();
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppleColors.danger,
        ),
      );
    }
  }

  void _showOptionalLocationSheet() {
    String selectedCity = defaultCity;
    String selectedBarangay = defaultBarangay;
    final streetCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isBulihan = isBulihanArea(city: selectedCity, barangay: selectedBarangay);
            final availableBarangays = caviteLocations[selectedCity] ?? [];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Set Delivery Location',
                        style: GoogleFonts.domine(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _darkText,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.inter(
                            color: _mutedText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Optional: Choose your Cavite / Bulihan address for faster delivery checkout.',
                    style: GoogleFonts.inter(color: _mutedText, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Delivery Fee Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isBulihan ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBulihan ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isBulihan ? Icons.local_shipping : Icons.motorcycle,
                          size: 20,
                          color: isBulihan ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isBulihan
                                ? 'FREE Delivery Fee (Bulihan Area, Silang)'
                                : 'Delivery via Lalamove: Deliveries outside Bulihan Area are dispatched via Lalamove.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isBulihan ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Municipality Dropdown
                  Text('Municipality / City', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCity,
                    isExpanded: true,
                    decoration: InputDecoration(
                      fillColor: _inputBackground,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: caviteLocations.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedCity = val;
                          selectedBarangay = caviteLocations[val]?.first ?? '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Barangay Dropdown
                  Text('Barangay / Zone', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: availableBarangays.contains(selectedBarangay) ? selectedBarangay : availableBarangays.firstOrNull,
                    isExpanded: true,
                    decoration: InputDecoration(
                      fillColor: _inputBackground,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: availableBarangays.map((b) {
                      final isB = bulihanBarangays.contains(b);
                      return DropdownMenuItem(
                        value: b,
                        child: Text(isB ? '$b (Bulihan)' : b),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedBarangay = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Street Address
                  Text('Street Address / House No. / Landmark', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: streetCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Block 10 Lot 5 Narra St.',
                      fillColor: _inputBackground,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Skip for now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final fullAddr = buildDeliveryAddressString(
                              streetAddress: streetCtrl.text,
                              barangay: selectedBarangay,
                              city: selectedCity,
                            );
                            context.read<OrderSessionProvider>().updateLocation(
                              title: '$selectedCity - $selectedBarangay',
                              subtitle: fullAddr,
                              isBulihan: isBulihan,
                            );
                            Navigator.pop(modalCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final auth = context.watch<AuthProvider>();

    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    // Login Sheet top position (40% from top), Sign Up sheet top position (0px - full screen)
    final sheetTop = _isSignUp ? 0.0 : screenHeight * 0.40;
    final sheetRadius = _isSignUp ? 0.0 : 32.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // A. Background Hero Image Layer (Top 42% Viewport)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.45,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isSignUp ? 0.2 : 1.0,
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
                          colors: [Color(0xFF2C1400), _primaryOrange],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Dark Scrim Gradient Overlay
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

                  // Hero Title Headline Text (Logo removed from top-left)
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
          ),

          // B. Expanding White Card Sheet (AnimatedPositioned Half-Page ↔ Full-Screen)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            top: sheetTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: _isSignUp,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _isSignUp
                      ? _buildSignUpContent(context, auth, topPadding)
                      : _buildLoginContent(context, auth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HALF-PAGE LOGIN CONTENT
  Widget _buildLoginContent(BuildContext context, AuthProvider auth) {
    return KeyedSubtree(
      key: const ValueKey('LoginContent'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Login',
                  style: GoogleFonts.domine(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                    onTap: _switchToSignUp,
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

              // Email Input
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

              // Password Input
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

              // Toggles Row
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

              // Primary Login Button
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

              // Divider
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

              // Google Button
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
            ],
          ),
        ),
      ),
    );
  }

  // FULL-SCREEN CREATE ACCOUNT CONTENT
  Widget _buildSignUpContent(BuildContext context, AuthProvider auth, double topPadding) {
    return KeyedSubtree(
      key: const ValueKey('SignUpContent'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _signUpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Back Arrow Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: _darkText, size: 24),
                    onPressed: _switchToLogin,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                'Create Account',
                style: GoogleFonts.domine(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join Saddle Ranch to order sizzling favorites, save your details, and unlock rewards.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _mutedText,
                  height: 1.4,
                ),
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

              // 1. Full Name (Letters and spaces only, no numbers)
              Text(
                'Full Name',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _signUpNameController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.\-]')),
                ],
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
                  final clean = value.trim();
                  if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(clean)) {
                    return 'Full name must contain letters only (no numbers).';
                  }
                  if (clean.length < 2) {
                    return 'Full name must be at least 2 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Email Address (Proper email regex validation)
              Text(
                'Email Address',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
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
                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address (e.g. name@example.com).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Phone Number (Starts with 09 and exactly 11 digits)
              Text(
                'Phone Number',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _signUpPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                autocorrect: false,
                enableSuggestions: false,
                style: GoogleFonts.inter(color: _darkText, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '09171234567',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your mobile phone number.';
                  }
                  final clean = value.trim();
                  if (!clean.startsWith('09')) {
                    return 'Phone number must start with 09.';
                  }
                  if (clean.length != 11) {
                    return 'Phone number must be exactly 11 digits (e.g. 09171234567).';
                  }
                  if (!RegExp(r'^09\d{9}$').hasMatch(clean)) {
                    return 'Please enter a valid 11-digit mobile number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 4. Password
              Text(
                'Password',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
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
              const SizedBox(height: 14),

              // 5. Confirm Password
              Text(
                'Confirm Password',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
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
              const SizedBox(height: 24),

              // Create Account CTA Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.busy ? null : _handleSignUpSubmit,
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
                          'Create Account',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Link
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
                    onTap: _switchToLogin,
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
        ),
      ),
    );
  }
}

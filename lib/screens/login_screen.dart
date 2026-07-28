import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/auth_provider.dart';
import '../theme/apple_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/landing-video.mp4');
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0); // Mute for ambient background
      await _videoController.play();
      if (mounted) {
        setState(() => _videoInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _videoInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    if (_videoInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }

  Future<void> _fillCustomerDemo() async {
    AppleTheme.hapticFeedback();
    await context.read<AuthProvider>().loginAsDemo(
          email: 'customer@saddleranch.ph',
          fullName: 'Juan Dela Cruz',
          phone: '09171234567',
        );
  }

  Future<void> _fillDeveloperDemo() async {
    AppleTheme.hapticFeedback();
    await context.read<AuthProvider>().loginAsDemo(
          email: 'dev@saddleranch.ph',
          fullName: 'Dev Tester',
          phone: '09998887766',
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      body: Stack(
        children: [
          // Top Area: Looping Landing Video Background
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_videoInitialized && _videoController.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3F2000), AppleColors.primaryAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Saddle Ranch',
                                style: GoogleFonts.domine(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Gradient overlay for smooth contrast transition
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top Branding Header Badge
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppleColors.primaryAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Saddle Ranch Sizzle',
                                style: GoogleFonts.domine(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: SizedBox.expand(),
                ),
              ],
            ),
          ),

          // Bottom Area: Foodpanda-Style Rounded Sheet Container (32px Radius)
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar pill
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppleColors.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Main Sheet Heading
                      Text(
                        'Sign up or log in',
                        style: GoogleFonts.domine(
                          color: AppleColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your preferred method to continue',
                        style: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 14,
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

                      // Single Primary Auth Method: Continue with Google
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
                            side: const BorderSide(color: AppleColors.cardBorder, width: 1.2),
                            backgroundColor: AppleColors.pureWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: auth.busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppleColors.primaryAccent,
                                  ),
                                )
                              : Row(
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
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        color: AppleColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Demo Access Strip
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppleColors.cardSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppleColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.sparkles, size: 15, color: AppleColors.primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  'Quick Demo Access',
                                  style: GoogleFonts.domine(
                                    color: AppleColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                      const SizedBox(height: 20),

                      // Terms and Privacy Policy Footer
                      Text.rich(
                        TextSpan(
                          text: 'By signing up you agree to our ',
                          style: GoogleFonts.inter(
                            color: AppleColors.mutedText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: GoogleFonts.inter(
                                color: AppleColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: GoogleFonts.inter(
                                color: AppleColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

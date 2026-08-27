import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;
import 'package:provider/provider.dart';

import '../core/config/google_auth_config.dart';
import '../providers/auth_provider.dart';

/// Web: show the same branded button users expect, then open a dialog with
/// Google's required GIS [renderButton] (avoids HtmlElementView clipping
/// inside the login sheet scroll view).
Widget buildGoogleSignInButton({
  required BuildContext context,
  required Future<void> Function() onMobilePressed,
}) {
  return const _WebGoogleSignInButton();
}

class _WebGoogleSignInButton extends StatelessWidget {
  const _WebGoogleSignInButton();

  static const _darkText = Color(0xFF1F2937);
  static const _cardBorder = Color(0xFFE5E7EB);

  Future<void> _openGoogleDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    if (!GoogleAuthConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Sign-In is not configured. Run with --dart-define=GOOGLE_SERVER_CLIENT_ID=...',
          ),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
      return;
    }

    // Ensure GIS is initialized before showing the official button.
    await auth.ensureGoogleReady();
    if (!context.mounted) return;

    if (!auth.googleReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In failed to initialize. Check your Web client ID and JavaScript origins.'),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _GoogleSignInDialog(auth: auth);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: busy ? null : () => _openGoogleDialog(context),
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
    );
  }
}

class _GoogleSignInDialog extends StatefulWidget {
  const _GoogleSignInDialog({required this.auth});

  final AuthProvider auth;

  @override
  State<_GoogleSignInDialog> createState() => _GoogleSignInDialogState();
}

class _GoogleSignInDialogState extends State<_GoogleSignInDialog> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;
  String? _status;

  @override
  void initState() {
    super.initState();
    _sub = GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is! GoogleSignInAuthenticationEventSignIn) return;

      setState(() => _status = 'Signing you in…');
      final ok = await widget.auth.completeGoogleSignInFromAccount(event.user);
      if (!mounted) return;

      if (ok) {
        Navigator.of(context, rootNavigator: true).pop();
        return;
      }

      final err = widget.auth.error ?? 'Google sign-in failed.';
      setState(() => _status = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
    }, onError: (Object e) {
      if (!mounted) return;
      setState(() => _status = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: $e'),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue with Google',
              style: GoogleFonts.domine(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the Google button below to choose your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            // Fixed size so the GIS platform view is visible (not clipped).
            SizedBox(
              height: 48,
              width: double.infinity,
              child: Center(
                child: google_web.renderButton(
                  configuration: google_web.GSIButtonConfiguration(
                    type: google_web.GSIButtonType.standard,
                    theme: google_web.GSIButtonTheme.outline,
                    size: google_web.GSIButtonSize.large,
                    text: google_web.GSIButtonText.continueWith,
                    shape: google_web.GSIButtonShape.rectangular,
                    logoAlignment: google_web.GSIButtonLogoAlignment.left,
                    minimumWidth: 280,
                  ),
                ),
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _status!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

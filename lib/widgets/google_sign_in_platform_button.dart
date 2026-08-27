import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'google_sign_in_platform_button_stub.dart'
    if (dart.library.html) 'google_sign_in_platform_button_web.dart'
    as platform_button;

/// Platform-aware Google Sign-In control.
/// - Mobile: custom "Continue with Google" that calls [AuthProvider.signInWithGoogle]
/// - Web: official GIS [renderButton] (required; authenticate() is unsupported)
class AppGoogleSignInButton extends StatelessWidget {
  const AppGoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return platform_button.buildGoogleSignInButton(
      context: context,
      onMobilePressed: () async {
        final auth = context.read<AuthProvider>();
        final ok = await auth.signInWithGoogle();
        if (!context.mounted) return;
        final err = auth.error;
        if (!ok && err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: const Color(0xFFF43F5E),
            ),
          );
        }
      },
    );
  }
}

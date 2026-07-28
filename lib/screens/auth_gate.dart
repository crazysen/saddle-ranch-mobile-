import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

/// Shows login → profile setup → app, and keeps session after first login.
class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    if (auth.needsProfileSetup) {
      return const ProfileSetupScreen();
    }

    return child;
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/apple_theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Account',
          style: GoogleFonts.domine(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppleColors.textPrimary,
          ),
        ),
        backgroundColor: AppleColors.pureWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppleColors.danger, size: 20),
            tooltip: 'Log Out',
            onPressed: () {
              AppleTheme.hapticFeedback();
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile User Surface Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppleColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppleColors.cardBorder),
              boxShadow: AppleColors.ambientShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppleColors.primaryAccent.withValues(alpha: 0.12),
                  backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                      ? Text(
                          (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'S').toUpperCase(),
                          style: GoogleFonts.domine(
                            color: AppleColors.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName : 'Saddle Ranch Guest',
                        style: GoogleFonts.domine(
                          color: AppleColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Not signed in',
                        style: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                      if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone!,
                          style: GoogleFonts.inter(
                            color: AppleColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppleColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppleColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 20, color: AppleColors.primaryAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Active session authenticated on this device. Offline mock mode enabled for zero-latency UI testing.',
                    style: GoogleFonts.inter(
                      color: AppleColors.mutedText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Prominent Apple-styled Log Out Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                AppleTheme.hapticFeedback();
                context.read<AuthProvider>().signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppleColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reset testing button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                AppleTheme.hapticFeedback();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppleColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Reset account session?',
                      style: GoogleFonts.domine(
                        color: AppleColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'This clears saved account session credentials on this device.',
                      style: GoogleFonts.inter(
                        color: AppleColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: AppleColors.mutedText),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppleColors.danger,
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<AuthProvider>().clearLocalAccount();
                }
              },
              icon: const Icon(LucideIcons.refreshCw, size: 14, color: AppleColors.mutedText),
              label: Text(
                'Reset test state',
                style: GoogleFonts.inter(
                  color: AppleColors.mutedText,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

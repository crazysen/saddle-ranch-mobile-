import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceAlt,
                  backgroundImage: user?.photoUrl != null
                      ? CachedNetworkImageProvider(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          (user?.fullName.isNotEmpty == true
                                  ? user!.fullName[0]
                                  : 'S')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName
                            : 'Saddle Ranch guest',
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone!,
                          style: const TextStyle(
                            color: AppColors.mutedDark,
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
          const SizedBox(height: 20),
          const Text(
            'Signed in with Google. You won’t be asked to log in again on this device.',
            style: TextStyle(color: AppColors.mutedDark, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: auth.busy
                ? null
                : () async {
                    await context.read<AuthProvider>().signOut();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cream,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Log out'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: auth.busy
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('Reset account on this device?'),
                        content: const Text(
                          'This clears your saved profile so you can test first-time login again.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<AuthProvider>().clearLocalAccount();
                    }
                  },
            child: const Text(
              'Reset first-time setup (testing)',
              style: TextStyle(color: AppColors.mutedDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

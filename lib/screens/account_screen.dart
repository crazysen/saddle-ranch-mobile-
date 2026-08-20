import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../theme/apple_theme.dart';
import '../widgets/confirmation_modal.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    AppleTheme.hapticFeedback();

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    await auth.completeProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ConfirmationModal.show(
        context,
        title: 'Profile Updated!',
        message: 'Your personal information has been saved successfully.',
        type: ConfirmationType.success,
      );
    }
  }

  Future<void> _handleLogout() async {
    AppleTheme.hapticFeedback();
    final confirm = await ConfirmationModal.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your Saddle Ranch account?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      type: ConfirmationType.alert,
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.domine(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          // Profile User Avatar & Email Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFFF7ED),
                  backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                      ? Text(
                          (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'S').toUpperCase(),
                          style: GoogleFonts.domine(
                            color: const Color(0xFFF59E0B),
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
                        user?.fullName.isNotEmpty == true ? user!.fullName : 'Saddle Ranch Customer',
                        style: GoogleFonts.domine(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'customer@saddleranch.ph',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Edit Profile Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: GoogleFonts.domine(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update your account display name and mobile number for your delivery orders.',
                    style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Full Name Field (letters only)
                  Text(
                    'Full Name',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 14),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.\-']")),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(LucideIcons.user, size: 18, color: Color(0xFF9CA3AF)),
                      fillColor: const Color(0xFFF9FAFB),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      if (val.isEmpty) return 'Full name is required';
                      if (!RegExp(r"^[a-zA-Z\s\.\-']+$").hasMatch(val)) {
                        return 'Full name must contain letters only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number Field (09XXXXXXXXX)
                  Text(
                    'Contact Number',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 14),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: InputDecoration(
                      hintText: '09XXXXXXXXX (11 digits)',
                      prefixIcon: const Icon(LucideIcons.phone, size: 18, color: Color(0xFF9CA3AF)),
                      fillColor: const Color(0xFFF9FAFB),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      if (val.isEmpty) return 'Contact number is required';
                      if (!val.startsWith('09') || val.length != 11) {
                        return 'Must start with 09 and have 11 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.workSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF43F5E),
                side: const BorderSide(color: Color(0xFFFECDD3), width: 1.5),
                backgroundColor: const Color(0xFFFFF1F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFF43F5E)),
              label: Text(
                'Log Out',
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFFF43F5E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

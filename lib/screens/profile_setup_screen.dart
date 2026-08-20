import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/order_session_provider.dart';
import '../utils/cavite_locations.dart';
import '../utils/ph_mobile_number.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final TextEditingController _streetCtrl = TextEditingController();
  String _selectedCity = defaultCity;
  String _selectedBarangay = defaultBarangay;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    final user = context.read<AuthProvider>().user;
    final fallbackName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Valued Customer');
    
    await context.read<AuthProvider>().completeProfile(
      fullName: fallbackName,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      if (mounted) setState(() => _nameError = 'Please enter your full name.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(name)) {
      if (mounted) setState(() => _nameError = 'Full name must contain letters only (no numbers).');
      return;
    }
    if (mounted) setState(() => _nameError = null);

    if (_phoneCtrl.text.trim().isNotEmpty) {
      final phoneError = PhMobileNumber.validate(_phoneCtrl.text, required: true);
      if (mounted) setState(() => _phoneError = phoneError);
      if (phoneError != null) return;
    }

    final orderSession = context.read<OrderSessionProvider>();
    final auth = context.read<AuthProvider>();

    if (_streetCtrl.text.trim().isNotEmpty) {
      final fullAddr = buildDeliveryAddressString(
        streetAddress: _streetCtrl.text,
        barangay: _selectedBarangay,
        city: _selectedCity,
      );
      final isBulihan = isBulihanArea(city: _selectedCity, barangay: _selectedBarangay);
      orderSession.updateLocation(
        title: '$_selectedCity - $_selectedBarangay',
        subtitle: fullAddr,
        isBulihan: isBulihan,
      );
    }

    await auth.completeProfile(
      fullName: name,
      phone: _phoneCtrl.text.trim().isNotEmpty ? PhMobileNumber.normalize(_phoneCtrl.text) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBulihan = isBulihanArea(city: _selectedCity, barangay: _selectedBarangay);
    final availableBarangays = caviteLocations[_selectedCity] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Details & Location',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: auth.busy ? null : _skip,
            child: const Text('Skip for now', style: TextStyle(color: AppColors.amberSoft, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Welcome! Set up your profile and primary delivery location (optional) for faster orders.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            auth.user?.email ?? '',
            style: const TextStyle(
              color: AppColors.amberSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // 1. Full Name (String only)
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.\-]')),
            ],
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: 'Full name (Letters only)',
              hintText: 'e.g. Juan Dela Cruz',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 14),

          // 2. Mobile Phone
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            onChanged: (_) {
              if (_phoneError != null) {
                setState(() => _phoneError = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Mobile number (09XXXXXXXXX)',
              hintText: '09171234567',
              errorText: _phoneError,
            ),
          ),
          const SizedBox(height: 24),

          // 3. Location Selector (Optional)
          Text(
            'Default Delivery Location (Optional)',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),

          // Dynamic Delivery Fee Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isBulihan ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBulihan ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
              ),
            ),
            child: Row(
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
                        : 'Delivery via Lalamove: Out-of-area dispatched via rider.',
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
          const SizedBox(height: 12),

          // Municipality
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Municipality / City'),
            items: caviteLocations.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCity = val;
                  _selectedBarangay = caviteLocations[val]?.first ?? '';
                });
              }
            },
          ),
          const SizedBox(height: 12),

          // Barangay
          DropdownButtonFormField<String>(
            initialValue: availableBarangays.contains(_selectedBarangay) ? _selectedBarangay : availableBarangays.firstOrNull,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Barangay / Zone'),
            items: availableBarangays.map((b) {
              final isB = bulihanBarangays.contains(b);
              return DropdownMenuItem(value: b, child: Text(isB ? '$b (Bulihan)' : b));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedBarangay = val);
            },
          ),
          const SizedBox(height: 12),

          // Street Address
          TextField(
            controller: _streetCtrl,
            decoration: const InputDecoration(
              labelText: 'Street Address / House No. / Landmark',
              hintText: 'e.g. Block 26 Lot 17 Narra St.',
            ),
          ),

          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: auth.busy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: auth.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Save & Continue',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

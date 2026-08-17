import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/order_session_provider.dart';
import '../theme/apple_theme.dart';
import '../utils/deep_link_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyTable(String table) {
    if (_handled || !mounted) return;
    _handled = true;
    final normalized = table.padLeft(2, '0');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Text(
                  'Table #$normalized Recognized',
                  style: GoogleFonts.domine(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppleColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select how you would like your order served:',
                  style: GoogleFonts.inter(color: AppleColors.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Dine-In Option
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E5E7)),
                  ),
                  tileColor: const Color(0xFFF7F7F8),
                  leading: const Icon(LucideIcons.utensils, color: AppleColors.primaryAccent),
                  title: Text(
                    'Dine-In',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    'Served hot on sizzling platters directly to Table #$normalized.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppleColors.mutedText),
                  ),
                  onTap: () {
                    context.read<OrderSessionProvider>().startDineInFromTable(
                          normalized,
                          fulfillment: OrderMode.dineIn,
                        );
                    Navigator.pop(modalCtx);
                    Navigator.pop(context, normalized);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Table $normalized Dine-In activated!'),
                        backgroundColor: AppleColors.primaryAccent,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Express Takeout Option
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E5E7)),
                  ),
                  tileColor: const Color(0xFFF7F7F8),
                  leading: const Icon(LucideIcons.packageCheck, color: Color(0xFFE65100)),
                  title: Text(
                    'Express Takeout (To-Go)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    'Packaged to-go while sitting in-house.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppleColors.mutedText),
                  ),
                  onTap: () {
                    context.read<OrderSessionProvider>().startDineInFromTable(
                          normalized,
                          fulfillment: OrderMode.expressTakeout,
                        );
                    Navigator.pop(modalCtx);
                    Navigator.pop(context, normalized);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Table $normalized Express Takeout activated!'),
                        backgroundColor: const Color(0xFFE65100),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final uri = Uri.tryParse(raw);
      if (uri != null) {
        final table = extractTableFromUri(uri);
        if (table != null) {
          _applyTable(table);
          return;
        }
      }

      // Plain table number like "05" or "5"
      final digits = RegExp(r'^\d{1,2}$').firstMatch(raw.trim());
      if (digits != null) {
        _applyTable(digits.group(0)!);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Table QR Code', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.amber, width: 3),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Point your camera at the QR code on your table tent',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

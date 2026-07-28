import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/order_session_provider.dart';
import '../utils/deep_link_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _applyTable(String table) {
    if (_handled || !mounted) return;
    _handled = true;
    final normalized = table.padLeft(2, '0');
    context.read<OrderSessionProvider>().startDineInFromTable(table);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(table);
    messenger.showSnackBar(
      SnackBar(content: Text('Table $normalized ready — order from your seat')),
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
        title: const Text('Scan table QR', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.amber, width: 3),
                    ),
                  ),
                ),
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Text(
                    'Point at the QR on your table tent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Or enter table number',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 05',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final value = _manualCtrl.text.trim();
                        if (value.isEmpty) return;
                        _applyTable(value);
                      },
                      child: const Text('Go'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/apple_theme.dart';

enum ConfirmationType { success, info, alert, error }

class ConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final ConfirmationType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'OK',
    this.cancelLabel,
    this.type = ConfirmationType.info,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String? cancelLabel,
    ConfirmationType type = ConfirmationType.info,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    AppleTheme.hapticFeedback();
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConfirmationModal(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirm?.call();
        },
        onCancel: () {
          Navigator.of(ctx).pop(false);
          onCancel?.call();
        },
      ),
    );
  }

  Color get _accentColor {
    switch (type) {
      case ConfirmationType.success:
        return const Color(0xFF10B981);
      case ConfirmationType.alert:
      case ConfirmationType.info:
        return const Color(0xFFF59E0B);
      case ConfirmationType.error:
        return const Color(0xFFEF4444);
    }
  }

  IconData get _icon {
    switch (type) {
      case ConfirmationType.success:
        return LucideIcons.checkCircle2;
      case ConfirmationType.info:
        return LucideIcons.info;
      case ConfirmationType.alert:
        return LucideIcons.alertTriangle;
      case ConfirmationType.error:
        return LucideIcons.xCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(_icon, color: _accentColor, size: 28),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.domine(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (cancelLabel != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          cancelLabel!,
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4B5563),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.workSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

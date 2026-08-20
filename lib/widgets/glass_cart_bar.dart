import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/apple_theme.dart';
import 'view_order_modal.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

/// Floating "VIEW YOUR ORDER" Pill Bar matching the floating style in Image 2
class AlwaysOnViewCartBar extends StatelessWidget {
  final VoidCallback? onOrderPlaced;

  const AlwaysOnViewCartBar({
    super.key,
    this.onOrderPlaced,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return GestureDetector(
      onTap: () {
        AppleTheme.hapticFeedback();
        ViewOrderModal.show(context, onOrderPlaced: onOrderPlaced);
      },
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B), // Saddle Ranch vibrant amber-orange
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Circular Badge with Item Count
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${cart.itemCount}',
                style: GoogleFonts.workSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title and Subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIEW YOUR ORDER',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SADDLE RANCH ONLINE ORDER',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF78350F),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Right Total Amount in Western font
            Text(
              _peso.format(cart.totalAmount),
              style: GoogleFonts.domine(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/apple_theme.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

class GlassCartBar extends StatelessWidget {
  final VoidCallback onTapViewCart;

  const GlassCartBar({
    super.key,
    required this.onTapViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.itemCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppleColors.pureWhite.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppleColors.cardBorder.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: AppleColors.ambientShadow,
            ),
            child: Row(
              children: [
                // Cart Icon with Badge Count
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppleColors.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        LucideIcons.shoppingBag,
                        color: AppleColors.primaryAccent,
                        size: 22,
                      ),
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppleColors.primaryAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Items Count & Total Price in Domine Bold
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} in cart',
                        style: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _peso.format(cart.totalAmount),
                        style: GoogleFonts.domine(
                          color: AppleColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // High-contrast Orange CTA Button
                ElevatedButton(
                  onPressed: () {
                    AppleTheme.hapticFeedback();
                    onTapViewCart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppleColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Cart',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

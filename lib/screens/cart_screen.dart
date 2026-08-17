import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../widgets/view_order_modal.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Your Cart',
          style: GoogleFonts.domine(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.shoppingBag, size: 48, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.domine(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add something sizzling from our menu',
                    style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                            // Food Thumbnail Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: item.product.imagePath != null && item.product.imagePath!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.product.imagePath!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Container(
                                          color: const Color(0xFFF3F4F6),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, _, _) => Container(
                                          color: const Color(0xFFF3F4F6),
                                          child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 24),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFF3F4F6),
                                        child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 24),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Item Name & Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.domine(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _peso.format(item.product.price),
                                    style: GoogleFonts.domine(
                                      color: const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    AppleTheme.hapticFeedback();
                                    cart.updateQuantity(item.product.id, item.quantity - 1);
                                  },
                                  icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF4B5563)),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.workSans(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    AppleTheme.hapticFeedback();
                                    cart.updateQuantity(item.product.id, item.quantity + 1);
                                  },
                                  icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFFF59E0B)),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    AppleTheme.hapticFeedback();
                                    cart.remove(item.product.id);
                                  },
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFF43F5E)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Checkout Card with proper bottom inset so it floats cleanly above bottom nav
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 96 + bottomInset),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal (${cart.itemCount} items)',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _peso.format(cart.subtotal),
                            style: GoogleFonts.domine(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            AppleTheme.hapticFeedback();
                            ViewOrderModal.show(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed to Checkout',
                                style: GoogleFonts.workSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/apple_theme.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

class AppleFoodCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const AppleFoodCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItem = cart.items.where((i) => i.product.id == product.id).firstOrNull;
    final inCartCount = cartItem?.quantity ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            AppleTheme.hapticFeedback();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High-res food image with subtle corner rounding
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 11,
                        child: product.imagePath != null && product.imagePath!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.imagePath!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  color: const Color(0xFFF4F4F6),
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                                  ),
                                ),
                                errorWidget: (_, _, _) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                    ),
                    // Circular '+' or quantity badge on the bottom right of the image
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: product.inStock
                            ? () {
                                AppleTheme.hapticFeedback();
                                cart.add(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
                                    duration: const Duration(milliseconds: 700),
                                    backgroundColor: const Color(0xFFF59E0B),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: inCartCount > 0
                              ? Text(
                                  '$inCartCount',
                                  style: GoogleFonts.workSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.plus,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dish Title in Domine bold font
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.domine(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const Spacer(),

                // Price tag in bold Saddle Ranch Amber (NO stock indicator)
                Text(
                  _peso.format(product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.domine(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF4F4F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood,
        color: Color(0xFFF59E0B),
        size: 32,
      ),
    );
  }
}

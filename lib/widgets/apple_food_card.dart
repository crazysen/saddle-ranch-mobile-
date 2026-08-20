import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/apple_theme.dart';

import '../utils/image_url_helper.dart';

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
    final normalizedUrl = ImageUrlHelper.normalize(product.imagePath);

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
                // High-res food image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 11,
                    child: normalizedUrl != null && normalizedUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: normalizedUrl,
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
                const SizedBox(height: 8),

                // Dish Title in Domine bold font
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.domine(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),

                // Price tag in bold Saddle Ranch Amber
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
                const Spacer(),

                // Full "Add to Cart" Button under Price Tag
                if (inCartCount == 0)
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: product.inStock
                          ? () {
                              AppleTheme.hapticFeedback();
                              cart.add(product);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        product.inStock ? 'Add to Cart' : 'Sold Out',
                        style: GoogleFonts.workSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {
                            AppleTheme.hapticFeedback();
                            cart.updateQuantity(product.id, inCartCount - 1);
                          },
                          icon: Icon(
                            inCartCount == 1 ? LucideIcons.trash2 : LucideIcons.minus,
                            size: 14,
                            color: inCartCount == 1 ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          '$inCartCount in Cart',
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {
                            AppleTheme.hapticFeedback();
                            cart.add(product);
                          },
                          icon: const Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
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

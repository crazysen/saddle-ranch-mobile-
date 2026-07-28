import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/apple_theme.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

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

    return Container(
      decoration: BoxDecoration(
        color: AppleColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppleColors.cardBorder, width: 1),
        boxShadow: AppleColors.ambientShadow,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High-res food image with subtle corner rounding (Radius 16)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: product.imagePath != null && product.imagePath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imagePath!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: AppleColors.cardSurface,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Dish Title in Domine bold font
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.domine(
                    color: AppleColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),

                // Description truncated cleanly in Inter font
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppleColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const Spacer(),

                // Bottom Row: Price tag in bold orange Domine font next to a pill-shaped + Add button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _peso.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.domine(
                          color: AppleColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Material(
                      color: product.inStock ? AppleColors.primaryAccent : AppleColors.cardBorder,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: product.inStock
                            ? () {
                                AppleTheme.hapticFeedback();
                                cart.add(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
                                    duration: const Duration(milliseconds: 900),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.plus,
                                size: 14,
                                color: product.inStock ? Colors.white : AppleColors.mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: GoogleFonts.inter(
                                  color: product.inStock ? Colors.white : AppleColors.mutedText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
      color: AppleColors.cardSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_fire_department,
        color: AppleColors.primaryAccent,
        size: 36,
      ),
    );
  }
}

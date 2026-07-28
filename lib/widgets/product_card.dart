import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: product.imagePath != null && product.imagePath!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: AppColors.surfaceAlt),
                          errorWidget: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            _peso.format(product.price),
                            style: const TextStyle(
                              color: AppColors.amberSoft,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 34,
                            width: 34,
                            child: IconButton.filled(
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: product.inStock
                                    ? AppColors.amber
                                    : AppColors.borderMuted,
                                foregroundColor: AppColors.onAmber,
                              ),
                              onPressed: product.inStock
                                  ? () {
                                      cart.add(product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product.name} added'),
                                          duration: const Duration(milliseconds: 900),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: const Icon(Icons.local_fire_department, color: AppColors.amber, size: 36),
    );
  }
}

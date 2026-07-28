import 'package:flutter/material.dart';

import '../models/product.dart';
import 'apple_food_card.dart';

export 'apple_food_card.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppleFoodCard(product: product, onTap: onTap);
  }
}

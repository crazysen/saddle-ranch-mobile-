import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/menu_provider.dart';
import '../utils/menu_category.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_card.dart';
import '../widgets/table_banner.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final products = menu.filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.cream),
            ),
            Text(
              menu.selectedCategory.subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const TableBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: menu.setSearch,
              decoration: const InputDecoration(
                hintText: 'Search sizzling favorites...',
                prefixIcon: Icon(Icons.search, color: AppColors.mutedDark),
              ),
            ),
          ),
          CategoryChips(
            selected: menu.selectedCategory,
            onSelected: menu.setCategory,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: menu.loading && menu.products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                : products.isEmpty
                    ? const Center(
                        child: Text(
                          'No items in this category yet.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: products[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

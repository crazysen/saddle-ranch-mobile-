import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/menu_provider.dart';
import '../utils/menu_category.dart';
import '../widgets/category_chips.dart';
import '../widgets/glass_cart_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/table_banner.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback? onOrderPlaced;

  const MenuScreen({super.key, this.onOrderPlaced});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final products = menu.filteredProducts;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Menu',
              style: GoogleFonts.domine(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              menu.selectedCategory.subtitle,
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const TableBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  onChanged: menu.setSearch,
                  style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search sizzling favorites...',
                    hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                    ),
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
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                    : products.isEmpty
                        ? Center(
                            child: Text(
                              'No items in this category yet.',
                              style: GoogleFonts.workSans(color: const Color(0xFF6B7280)),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 110 + bottomInset),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.76,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return ProductCard(product: products[index]);
                            },
                          ),
              ),
            ],
          ),

          // Floating "VIEW YOUR ORDER" Pill Bar matching the floating navigation bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: AlwaysOnViewCartBar(onOrderPlaced: onOrderPlaced),
          ),
        ],
      ),
    );
  }
}

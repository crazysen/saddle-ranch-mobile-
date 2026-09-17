import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/menu_category.dart';

/// Web-matching category tab bar: Popular · Rice Meals · …
class CategoryChips extends StatelessWidget {
  final MenuCategory selected;
  final ValueChanged<MenuCategory> onSelected;

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1612),
        border: Border(
          top: BorderSide(color: Color(0xFF262627)),
          bottom: BorderSide(color: Color(0xFF262627)),
        ),
      ),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: MenuCategory.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 20),
          itemBuilder: (context, index) {
            final category = MenuCategory.values[index];
            final isSelected = category == selected;
            return InkWell(
              onTap: () => onSelected(category),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      category.label,
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFFFFC174)
                            : const Color(0xFF8C7A6B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 2,
                      width: isSelected ? _underlineWidth(category.label) : 0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _underlineWidth(String label) {
    // Approximate text width so the amber rule tracks the label like web
    return (label.length * 6.8).clamp(28.0, 120.0);
  }
}

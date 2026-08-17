import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/menu_category.dart';

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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: MenuCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = MenuCategory.values[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            selectedColor: const Color(0xFFF59E0B),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            labelStyle: GoogleFonts.workSans(
              color: isSelected ? Colors.white : const Color(0xFF374151),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
              width: 1,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

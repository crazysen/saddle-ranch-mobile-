import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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
      height: 44,
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
            selectedColor: AppColors.amber,
            backgroundColor: AppColors.surfaceAlt,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onAmber : AppColors.cream,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.amber : AppColors.border,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

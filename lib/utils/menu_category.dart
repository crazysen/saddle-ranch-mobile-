import '../models/product.dart';

enum MenuCategory {
  all,
  sizzling,
  filipino,
  barkada,
  drinks,
}

extension MenuCategoryX on MenuCategory {
  String get label {
    switch (this) {
      case MenuCategory.all:
        return 'All';
      case MenuCategory.sizzling:
        return 'Rice Meals';
      case MenuCategory.filipino:
        return 'Authentic Filipino';
      case MenuCategory.barkada:
        return 'Barkada Platters';
      case MenuCategory.drinks:
        return 'Drinks and Extra Rice';
    }
  }

  String get subtitle {
    switch (this) {
      case MenuCategory.all:
        return 'Full menu';
      case MenuCategory.sizzling:
        return 'Sizzling Rice Meals';
      case MenuCategory.filipino:
        return 'Authentic Filipino Cuisine';
      case MenuCategory.barkada:
        return 'Barkada Platters';
      case MenuCategory.drinks:
        return 'Drinks and Extra Rice';
    }
  }

  int get sortOrder {
    switch (this) {
      case MenuCategory.all:
        return 0;
      case MenuCategory.sizzling:
        return 1;
      case MenuCategory.filipino:
        return 2;
      case MenuCategory.barkada:
        return 3;
      case MenuCategory.drinks:
        return 4;
    }
  }
}

MenuCategory categoryForProduct(Product product) {
  final cat = (product.category ?? '').toLowerCase();
  final name = product.name.toLowerCase();

  // 1. Drinks & Extra Rice
  if (cat.contains('drink') ||
      (cat.contains('rice') && cat.contains('extra')) ||
      name.contains('tea') ||
      name.contains('cucumber') ||
      name.contains('extra rice') ||
      name.contains('beverage') ||
      name.contains('juice') ||
      name.contains('soda')) {
    return MenuCategory.drinks;
  }

  // 2. Barkada Platters
  if (cat.contains('platter') ||
      cat.contains('barkada') ||
      name.startsWith('platter')) {
    return MenuCategory.barkada;
  }

  // 3. Authentic Filipino Cuisine
  if (cat.contains('filipino') ||
      name.contains('kare-kare') ||
      name.contains('adobo') ||
      name.contains('sinigang')) {
    return MenuCategory.filipino;
  }

  // 4. Sizzling Rice Meals (Default)
  return MenuCategory.sizzling;
}

List<Product> filterByCategory(List<Product> products, MenuCategory category) {
  if (category == MenuCategory.all) {
    // Sort products by required category order:
    // 1. Rice Meals
    // 2. Authentic Filipino
    // 3. Barkada Platters
    // 4. Drinks and Extra Rice
    final sorted = List<Product>.from(products);
    sorted.sort((a, b) {
      final catA = categoryForProduct(a).sortOrder;
      final catB = categoryForProduct(b).sortOrder;
      if (catA != catB) return catA.compareTo(catB);
      return a.id.compareTo(b.id);
    });
    return sorted;
  }
  return products.where((p) => categoryForProduct(p) == category).toList();
}

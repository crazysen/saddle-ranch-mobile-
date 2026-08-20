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
  final name = product.name.toLowerCase().trim();
  final cat = (product.category ?? '').toLowerCase().trim();

  // 1. Barkada Platters (Platters always go to Barkada Platters)
  if (name.startsWith('platter') ||
      name.contains('platter') ||
      cat.contains('platter') ||
      cat.contains('barkada')) {
    return MenuCategory.barkada;
  }

  // 2. Authentic Filipino Cuisine (Heritage classics)
  if (name.contains('kare-kare') ||
      name.contains('adobo') ||
      name.contains('sinigang') ||
      name.contains('bulalo') ||
      name.contains('lechon') ||
      cat.contains('filipino') ||
      cat.contains('authentic')) {
    return MenuCategory.filipino;
  }

  // 3. Sizzling Rice Meals (Explicit Sizzling Dishes & Rice Meals - including Sizzling Burger Steak!)
  if (name.contains('burger') ||
      name.contains('steak') ||
      name.contains('inasal') ||
      name.contains('sisig') ||
      name.contains('porkchop') ||
      name.contains('pork chop') ||
      name.contains('tapsilog') ||
      name.contains('tocilog') ||
      name.contains('tilapia') ||
      name.contains('bangus') ||
      name.contains('spicy beef') ||
      name.contains('teriyaki') ||
      name.contains('sizzling') ||
      (cat.contains('sizzling') && !name.contains('extra rice')) ||
      (cat.contains('rice meal') && !name.contains('extra rice'))) {
    return MenuCategory.sizzling;
  }

  // 4. Drinks and Extra Rice (Only actual drinks, beverages, and extra rice!)
  if (name.contains('tea') ||
      name.contains('cucumber') ||
      name.contains('extra rice') ||
      name.contains('juice') ||
      name.contains('soda') ||
      name.contains('beverage') ||
      name.contains('pitcher') ||
      name.contains('drink') ||
      name == 'extra rice' ||
      name == 'rice' ||
      cat.contains('drink') ||
      (cat.contains('extra') && cat.contains('rice'))) {
    return MenuCategory.drinks;
  }

  // 5. Default fallback to Sizzling Rice Meals
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

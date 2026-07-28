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
        return 'Sizzling';
      case MenuCategory.filipino:
        return 'Filipino';
      case MenuCategory.barkada:
        return 'Barkada';
      case MenuCategory.drinks:
        return 'Drinks';
    }
  }

  String get subtitle {
    switch (this) {
      case MenuCategory.all:
        return 'Full menu';
      case MenuCategory.sizzling:
        return 'Rice meals';
      case MenuCategory.filipino:
        return 'Heritage classics';
      case MenuCategory.barkada:
        return 'Sharing platters';
      case MenuCategory.drinks:
        return 'Drinks & rice';
    }
  }
}

MenuCategory categoryForProduct(Product product) {
  final name = product.name.toLowerCase();

  if (name.contains('tea') ||
      name.contains('juice') ||
      name.contains('extra garlic rice') ||
      name.contains('beverage') ||
      name.contains('drink') ||
      name.contains('soda')) {
    return MenuCategory.drinks;
  }

  if (name.contains('sisig') ||
      name.contains('lechon') ||
      name.contains('bulalo') ||
      name.contains('bangus')) {
    return MenuCategory.filipino;
  }

  if (name.contains('ribeye') ||
      name.contains('t-bone') ||
      name.contains('gambas') ||
      name.contains('squid') ||
      name.contains('platter') ||
      name.contains('shrimp')) {
    return MenuCategory.barkada;
  }

  // Pepper rice, inasal, pork chop, burger steak, default sizzling rice meals
  return MenuCategory.sizzling;
}

List<Product> filterByCategory(List<Product> products, MenuCategory category) {
  if (category == MenuCategory.all) return products;
  return products.where((p) => categoryForProduct(p) == category).toList();
}

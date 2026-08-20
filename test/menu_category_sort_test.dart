import 'package:flutter_test/flutter_test.dart';
import 'package:saddle_ranch_mobile/models/product.dart';
import 'package:saddle_ranch_mobile/utils/menu_category.dart';

void main() {
  group('Menu Category & Sort Order Tests', () {
    test('MenuCategory labels and subtitles match requirements', () {
      expect(MenuCategory.sizzling.label, 'Rice Meals');
      expect(MenuCategory.filipino.label, 'Authentic Filipino');
      expect(MenuCategory.barkada.label, 'Barkada Platters');
      expect(MenuCategory.drinks.label, 'Drinks and Extra Rice');
    });

    test('categoryForProduct accurately assigns categories based on field or fallback', () {
      const riceMeal = Product(
        id: 1,
        name: 'Sizzling Chicken Inasal',
        description: '',
        price: 120,
        stockQuantity: 10,
        isActive: true,
        category: 'Sizzling Rice Meals',
      );
      const filipino = Product(
        id: 2,
        name: 'Pork Sinigang',
        description: '',
        price: 150,
        stockQuantity: 10,
        isActive: true,
        category: 'Authentic Filipino Cuisine',
      );
      const barkada = Product(
        id: 3,
        name: 'Platter Sisig',
        description: '',
        price: 320,
        stockQuantity: 10,
        isActive: true,
        category: 'Barkada Platters',
      );
      const drinks = Product(
        id: 4,
        name: 'Red Iced Tea',
        description: '',
        price: 45,
        stockQuantity: 10,
        isActive: true,
        category: 'Drinks & Extra Rice',
      );
      const extraRice = Product(
        id: 5,
        name: 'Extra Rice',
        description: '',
        price: 20,
        stockQuantity: 10,
        isActive: true,
      );
      const burgerSteak = Product(
        id: 6,
        name: 'Sizzling Burger Steak',
        description: 'Tender burger patties in mushroom gravy',
        price: 95,
        stockQuantity: 10,
        isActive: true,
        category: 'Drinks & Extra Rice', // Test corrupted/legacy category tag
      );

      expect(categoryForProduct(riceMeal), MenuCategory.sizzling);
      expect(categoryForProduct(burgerSteak), MenuCategory.sizzling);
      expect(categoryForProduct(filipino), MenuCategory.filipino);
      expect(categoryForProduct(barkada), MenuCategory.barkada);
      expect(categoryForProduct(drinks), MenuCategory.drinks);
      expect(categoryForProduct(extraRice), MenuCategory.drinks);
    });

    test('filterByCategory with MenuCategory.all sorts in required order', () {
      const extraRice = Product(
        id: 10,
        name: 'Extra Rice',
        description: '',
        price: 20,
        stockQuantity: 10,
        isActive: true,
      );
      const platterSisig = Product(
        id: 20,
        name: 'Platter Sisig',
        description: '',
        price: 320,
        stockQuantity: 10,
        isActive: true,
      );
      const kareKare = Product(
        id: 30,
        name: 'Kare-Kare',
        description: '',
        price: 180,
        stockQuantity: 10,
        isActive: true,
      );
      const chickenInasal = Product(
        id: 40,
        name: 'Sizzling Chicken Inasal',
        description: '',
        price: 120,
        stockQuantity: 10,
        isActive: true,
      );

      final mixed = [extraRice, platterSisig, kareKare, chickenInasal];
      final sorted = filterByCategory(mixed, MenuCategory.all);

      // Expected sort order:
      // 1. Rice Meals (chickenInasal)
      // 2. Authentic Filipino (kareKare)
      // 3. Barkada Platters (platterSisig)
      // 4. Drinks and Extra Rice (extraRice)
      expect(sorted[0].name, 'Sizzling Chicken Inasal');
      expect(sorted[1].name, 'Kare-Kare');
      expect(sorted[2].name, 'Platter Sisig');
      expect(sorted[3].name, 'Extra Rice');
    });
  });
}

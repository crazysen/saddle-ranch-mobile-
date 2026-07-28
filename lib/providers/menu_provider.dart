import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/promo_banner.dart';
import '../services/api_service.dart';
import '../utils/menu_category.dart';

class MenuProvider extends ChangeNotifier {
  final ApiService _api;

  MenuProvider({ApiService? api}) : _api = api ?? ApiService();

  List<Product> _products = [];
  List<PromoBanner> _banners = [];
  MenuCategory _selectedCategory = MenuCategory.all;
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  List<Product> get products => _products;
  List<PromoBanner> get banners => _banners;
  MenuCategory get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get loading => _loading;
  String? get error => _error;

  List<Product> get filteredProducts {
    var list = filterByCategory(_products, _selectedCategory);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.fetchProducts(),
        _api.fetchBanners(),
      ]);
      _products = results[0] as List<Product>;
      _banners = results[1] as List<PromoBanner>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setCategory(MenuCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

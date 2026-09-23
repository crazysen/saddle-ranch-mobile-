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
  String _branch = 'Bulihan';
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  static const List<PromoBanner> defaultPromotionalDeals = [
    PromoBanner(
      id: 1,
      title: 'Sisig Saturdays Deal',
      badge: 'WEEKEND SPECIAL • 20% OFF',
      subtitle:
          'Enjoy 20% off our legendary 24-hour marinated Pork Sisig served on a smoking hot skillet with raw egg and calamansi.',
      imagePath:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB6QEUONokTX7mi1M1Wrie14cxeoNfVq5HyIS1sLOLWKbzZyh6OfegCBaNeH6E7uS37ugVc6jjmILNzIrmvE0tpXkOBCDP29HO1WZL69MsOd6lpwp4oX6ezfDjuAsLMCu57vBpiHDupWu3yDATuk2k_HgpQMi23Y7mifgQKqPJhc0GqDXCCk1tPooIkFyBCXPiESBHm8HKF8cp1ctvD0RZ39YNVxKG_2cPaPyfryUGBbaoIHhqqhq5R9BflPtI6jMfzsP3W6QStlttx',
      branch: 'all',
      isActive: true,
      displayOrder: 1,
    ),
    PromoBanner(
      id: 2,
      title: 'Cowboy Ribeye Special',
      badge: 'NEW ARRIVAL',
      subtitle: 'Bone-in, seared on smoking cast iron.',
      imagePath:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAqtvjGjUsuBGyzBHVhntcLtTHQL442EMNheO8rq-4bOP-zq35cYw-DswcOn6dpMuPv5ukX12iSEzREwKgb6iPoUk64ETmBeEcSAd_ACcZoIibAIU9yR4PAPlj2o5GbDfdalWoY2tkEYUIrX_067eJx75-iVNUhMQQwzXdK3OmEDSQSGelDLgr5zgcY5sN7zsIqaaHUGQXrLpgju8NF3deoQjQPo--R-W6fwR50zfB_tGo3dBdO2gM7hr6EUUVxLgCF5gCn94DbGA_N',
      branch: 'all',
      isActive: true,
      displayOrder: 2,
    ),
    PromoBanner(
      id: 3,
      title: 'Unlimited Rice & Soup',
      badge: 'DASMARIÑAS BRANCH • ₱79 UNLI RICE & SOUP',
      subtitle:
          'Unli rice & soup at selected products for both branches — special offer for only ₱79 at Dasmariñas Branch!',
      imagePath:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDT2sso9NgKHiCPPIkIfBBCfPNPUK_dgit8ctI0rtoMT_bXyQ21nRcx3ViyVnDNZTyTCVtYOSFJ8h_h3ZG451V7vUFX1LFMWyd6wQrV-4pevn9wO0H-wUZVYl0TBSwWt_bbQikBKmtygbJeYfSzWbAOcd32EpNo8TCvpmAamQoFlFfNvHrmpn32aUcJ7gi5IGdK9xpTad7qU6dSRSu2bty13h9_T3_GKF3mMrUI31pUXtjCvVgiLfQIkBBbjU_zY5SS0IrP8nvbh7QQ',
      branch: 'all',
      isActive: true,
      displayOrder: 3,
    ),
    PromoBanner(
      id: 4,
      title: 'Pulutan Happy Hour Specials',
      badge: 'HAPPY HOUR • 4PM - 7PM DAILY',
      subtitle:
          'Gather \'round the roadhouse hearth with ice-cold beverages and piping hot sizzling pulutan platters.',
      imagePath:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuMIwhrcJTtw4asxssNVZ2VWGxMaovy2G1K8R0Ix8yDYIZmMquCCDp47-9iSZeRJZPGoqUA_gstmSpYFxDQdS1nDIkmXqLfi-tQLTneA4ORWkxGtLYbCbkjLJ2sZcAuvum0fGxFxM8i2GzRSAaFKYWHdOIp6HsbA9GRrg84sBVlnpzrm4YyuS53vG9_x_SOV-OQNPEsIkecPojkMz-8yFDwZ07jXZ3SnUf-A_tEyuljflrAP4mCwWgHiFNvHAbJt-LBV66MAiCwKl',
      branch: 'all',
      isActive: true,
      displayOrder: 4,
    ),
  ];

  List<Product> get products => _products;
  List<PromoBanner> get banners {
    final active = _banners.where((b) {
      if (b.branch == 'all') return true;
      return b.branch.toLowerCase().contains(_branch.toLowerCase());
    }).toList();
    if (active.length >= 4) {
      return active;
    }
    return defaultPromotionalDeals;
  }

  MenuCategory get selectedCategory => _selectedCategory;
  String get branch => _branch;
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

  void setBranch(String branch) {
    if (_branch != branch) {
      _branch = branch;
      notifyListeners();
    }
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

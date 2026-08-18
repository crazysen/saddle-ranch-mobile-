import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _api;

  CartProvider({ApiService? api}) : _api = api ?? ApiService();

  final List<CartItem> _items = [];
  final Set<String> _usedVoucherCodes = {};
  String _branch = 'Bulihan';
  Voucher? _appliedVoucher;
  String? _voucherError;
  bool _validatingVoucher = false;

  List<CartItem> get items => List.unmodifiable(_items);
  Voucher? get appliedVoucher => _appliedVoucher;
  String? get voucherError => _voucherError;
  bool get validatingVoucher => _validatingVoucher;
  String get branch => _branch;

  bool isVoucherUsed(String code) => _usedVoucherCodes.contains(code.trim().toUpperCase());

  void markVoucherUsed(String code) {
    _usedVoucherCodes.add(code.trim().toUpperCase());
    notifyListeners();
  }

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (_appliedVoucher == null) return 0.0;
    return _appliedVoucher!.calculateDiscount(subtotal);
  }

  double get totalAmount {
    final total = subtotal - discountAmount;
    return total < 0 ? 0.0 : total;
  }

  bool get isEmpty => _items.isEmpty;

  void setBranch(String branch) {
    if (_branch != branch) {
      _branch = branch;
      for (final item in _items) {
        item.branch = branch;
      }
      // Re-validate voucher if branch changed
      if (_appliedVoucher != null) {
        if (_appliedVoucher!.branch != 'all' &&
            _appliedVoucher!.branch.toLowerCase() != branch.toLowerCase()) {
          _voucherError = 'Voucher only valid for ${_appliedVoucher!.branch} branch.';
          _appliedVoucher = null;
        }
      }
      notifyListeners();
    }
  }

  void add(Product product, {int quantity = 1}) {
    if (!product.inStockForBranch(_branch)) return;
    final maxStock = product.stockForBranch(_branch);

    final existingIndex = _items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final newQty = (_items[existingIndex].quantity + quantity).clamp(1, maxStock);
      _items[existingIndex].quantity = newQty;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity.clamp(1, maxStock),
        branch: _branch,
      ));
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    if (_appliedVoucher != null && subtotal < _appliedVoucher!.minSpend) {
      _appliedVoucher = null;
      _voucherError = 'Minimum spend not met.';
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final maxStock = _items[index].product.stockForBranch(_branch);
      _items[index].quantity = quantity.clamp(1, maxStock);
      if (_appliedVoucher != null && subtotal < _appliedVoucher!.minSpend) {
        _appliedVoucher = null;
        _voucherError = 'Minimum spend not met.';
      }
      notifyListeners();
    }
  }

  String? get appliedVoucherCode => _appliedVoucher?.code;

  void removeOne(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      if (_appliedVoucher != null && subtotal < _appliedVoucher!.minSpend) {
        _appliedVoucher = null;
        _voucherError = 'Minimum spend not met.';
      }
      notifyListeners();
    }
  }

  /// Apply voucher code via backend validation API
  Future<bool> applyVoucher(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    _validatingVoucher = true;
    _voucherError = null;
    notifyListeners();

    try {
      final res = await _api.validateVoucher(
        code: cleanCode,
        subtotal: subtotal,
        branch: _branch,
      );

      final voucherData = res['voucher'] is Map<String, dynamic>
          ? res['voucher'] as Map<String, dynamic>
          : <String, dynamic>{
              'code': cleanCode,
              'discount_type': 'percentage',
              'value': 10.0,
            };

      _appliedVoucher = Voucher.fromJson(voucherData);
      _voucherError = null;
      return true;
    } catch (e) {
      _appliedVoucher = null;
      _voucherError = e.toString().replaceAll('ApiException: ', '');
      return false;
    } finally {
      _validatingVoucher = false;
      notifyListeners();
    }
  }

  Future<bool> validateAndApplyVoucher(String code, String branch) async {
    setBranch(branch);
    return applyVoucher(code);
  }

  void removeVoucher() {
    _appliedVoucher = null;
    _voucherError = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _appliedVoucher = null;
    _voucherError = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() =>
      _items.map((i) => i.toOrderJson()).toList();
}

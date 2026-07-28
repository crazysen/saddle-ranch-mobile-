import 'package:flutter/foundation.dart';

enum OrderMode { dineIn, pickup, delivery }

extension OrderModeX on OrderMode {
  String get apiValue {
    switch (this) {
      case OrderMode.dineIn:
        return 'dine_in';
      case OrderMode.pickup:
        return 'pickup';
      case OrderMode.delivery:
        return 'delivery';
    }
  }

  String get label {
    switch (this) {
      case OrderMode.dineIn:
        return 'Dine-In';
      case OrderMode.pickup:
        return 'Pick-Up';
      case OrderMode.delivery:
        return 'Delivery';
    }
  }
}

class OrderSessionProvider extends ChangeNotifier {
  OrderMode _mode = OrderMode.pickup;
  String? _tableNumber;
  bool _tableLocked = false;

  OrderMode get mode => _mode;
  String? get tableNumber => _tableNumber;
  bool get tableLocked => _tableLocked;
  bool get isDineIn => _mode == OrderMode.dineIn && (_tableNumber?.isNotEmpty ?? false);

  void setMode(OrderMode mode) {
    _mode = mode;
    if (mode != OrderMode.dineIn && !_tableLocked) {
      _tableNumber = null;
    }
    notifyListeners();
  }

  /// Called when guest scans table QR or opens deep link `/dine-in?table=05`.
  void startDineInFromTable(String table) {
    final normalized = table.trim().padLeft(2, '0');
    _mode = OrderMode.dineIn;
    _tableNumber = normalized;
    _tableLocked = true;
    notifyListeners();
  }

  void setTableNumber(String? table) {
    if (_tableLocked) return;
    _tableNumber = table?.trim().isEmpty == true ? null : table?.trim();
    notifyListeners();
  }

  void clearTableLock() {
    _tableLocked = false;
    if (_mode == OrderMode.dineIn) {
      _tableNumber = null;
    }
    notifyListeners();
  }

  void reset() {
    _mode = OrderMode.pickup;
    _tableNumber = null;
    _tableLocked = false;
    notifyListeners();
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

enum OrderMode { dineIn, pickup, delivery, expressTakeout }

extension OrderModeX on OrderMode {
  String get apiValue {
    switch (this) {
      case OrderMode.dineIn:
        return 'dine_in';
      case OrderMode.expressTakeout:
        return 'express_takeout';
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
      case OrderMode.expressTakeout:
        return 'Express Takeout';
      case OrderMode.pickup:
        return 'Pick-Up';
      case OrderMode.delivery:
        return 'Delivery';
    }
  }
}

class OrderSessionProvider extends ChangeNotifier {
  final ApiService _api;

  OrderSessionProvider({ApiService? api}) : _api = api ?? ApiService();

  OrderMode _mode = OrderMode.pickup;
  String _branch = 'Bulihan'; // 'Bulihan' or 'Dasma'
  String? _tableNumber;
  bool _tableLocked = false;
  String _deliveryAddressTitle = 'Saddle Ranch Bulihan Main';
  String _deliveryAddressSubtitle = 'Aguinaldo Highway, Bulihan, Silang, Cavite';
  bool _isBulihanAddress = true;

  // Waiter buzzer state
  String _waiterCallStatus = 'idle'; // 'idle' | 'pending' | 'acknowledged'
  bool _isCallingWaiter = false;

  OrderMode get mode => _mode;
  String get branch => _branch;
  String? get tableNumber => _tableNumber;
  bool get tableLocked => _tableLocked;
  String get waiterCallStatus => _waiterCallStatus;
  bool get isCallingWaiter => _isCallingWaiter;
  String get deliveryAddressTitle => _deliveryAddressTitle;
  String get deliveryAddressSubtitle => _deliveryAddressSubtitle;
  bool get isBulihanAddress => _isBulihanAddress;

  bool get isDineIn => (_mode == OrderMode.dineIn || _mode == OrderMode.expressTakeout) && (_tableNumber?.isNotEmpty ?? false);

  void updateLocation({
    required String title,
    required String subtitle,
    required bool isBulihan,
  }) {
    _deliveryAddressTitle = title;
    _deliveryAddressSubtitle = subtitle;
    _isBulihanAddress = isBulihan;
    _branch = isBulihan ? 'Bulihan' : 'Dasma';
    notifyListeners();
  }

  // GPS Coordinates from Spec
  static const double bulihanLat = 14.2384;
  static const double bulihanLng = 120.9752;
  static const double dasmaLat = 14.3291;
  static const double dasmaLng = 120.9365;

  void setBranch(String newBranch) {
    if (_branch != newBranch) {
      _branch = newBranch;
      notifyListeners();
    }
  }

  void setMode(OrderMode mode) {
    _mode = mode;
    if (mode != OrderMode.dineIn && mode != OrderMode.expressTakeout && !_tableLocked) {
      _tableNumber = null;
    }
    notifyListeners();
  }

  /// Auto-detect if user is closer to Bulihan or Dasmariñas Branch
  Future<Map<String, dynamic>> autoDetectBranch() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lon = (data['longitude'] as num?)?.toDouble();
          final city = (data['city'] as String?)?.toLowerCase() ?? '';

          if (lat != null && lon != null) {
            final distBulihan = calculateDistance(lat, lon, bulihanLat, bulihanLng);
            final distDasma = calculateDistance(lat, lon, dasmaLat, dasmaLng);
            final selected = distBulihan <= distDasma ? 'Bulihan' : 'Dasma';
            final distance = distBulihan <= distDasma ? distBulihan : distDasma;
            setBranch(selected);
            return {
              'branch': selected,
              'distance': distance,
              'city': data['city'],
              'success': true,
            };
          } else if (city.contains('dasma') || city.contains('bacoor') || city.contains('imus')) {
            setBranch('Dasma');
            return {'branch': 'Dasma', 'city': data['city'], 'success': true};
          } else if (city.contains('silang') || city.contains('tagaytay') || city.contains('bulihan')) {
            setBranch('Bulihan');
            return {'branch': 'Bulihan', 'city': data['city'], 'success': true};
          }
        }
      }
    } catch (_) {}

    final fallback = _isBulihanAddress ? 'Bulihan' : 'Dasma';
    setBranch(fallback);
    return {'branch': fallback, 'success': false};
  }

  /// Select closest branch using Haversine formula
  String determineClosestBranch(double userLat, double userLng) {
    final distBulihan = calculateDistance(userLat, userLng, bulihanLat, bulihanLng);
    final distDasma = calculateDistance(userLat, userLng, dasmaLat, dasmaLng);
    final selected = distBulihan <= distDasma ? 'Bulihan' : 'Dasma';
    setBranch(selected);
    return selected;
  }

  /// Distance formula (Haversine in km) from System Spec
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // Earth radius km
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Called when guest scans table QR or opens deep link `/dine-in?table=05`.
  void startDineInFromTable(String table, {OrderMode fulfillment = OrderMode.dineIn}) {
    final normalized = table.trim().padLeft(2, '0');
    _mode = fulfillment;
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
    if (_mode == OrderMode.dineIn || _mode == OrderMode.expressTakeout) {
      _tableNumber = null;
    }
    notifyListeners();
  }

  /// Buzzer: Call Waiter
  Future<void> triggerCallWaiter() async {
    if (_tableNumber == null || _tableNumber!.isEmpty) return;
    _isCallingWaiter = true;
    _waiterCallStatus = 'pending';
    notifyListeners();

    try {
      await _api.callWaiter(tableNumber: _tableNumber!, branch: _branch);
    } catch (_) {
      // Still show pending state locally
    } finally {
      _isCallingWaiter = false;
      notifyListeners();
    }
  }

  /// Poll waiter buzzer status
  Future<void> pollWaiterStatus() async {
    if (_tableNumber == null || _tableNumber!.isEmpty) return;
    try {
      final status = await _api.getWaiterCallStatus(tableNumber: _tableNumber!);
      if (_waiterCallStatus != status) {
        _waiterCallStatus = status;
        notifyListeners();
      }
    } catch (_) {}
  }

  void reset() {
    _mode = OrderMode.pickup;
    _branch = 'Bulihan';
    _tableNumber = null;
    _tableLocked = false;
    _waiterCallStatus = 'idle';
    notifyListeners();
  }
}

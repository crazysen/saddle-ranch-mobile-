import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Override when pointing at a deployed Laravel host.
  static const String? overrideBaseUrl = null;

  static String get baseUrl {
    if (overrideBaseUrl != null) return overrideBaseUrl!;

    // Android emulator reaches host machine via 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }

  static String get products => '$baseUrl/products';
  static String get banners => '$baseUrl/banners';
  static String get orders => '$baseUrl/orders';
  static String get login => '$baseUrl/auth/login';
  static String get validateVoucher => '$baseUrl/vouchers/validate';
}

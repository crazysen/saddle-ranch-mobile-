class ApiConfig {
  /// Toggle bypassBackend to true only for offline fallback/testing.
  /// Set to false to connect directly to the live Laravel database hosted on Render.
  static bool bypassBackend = false;

  /// Live Render backend base URL
  static const String defaultRenderUrl = 'https://saddle-ranch-web.onrender.com/api/v1';

  /// Optional override for local development or custom environment
  static String? overrideBaseUrl;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    return defaultRenderUrl;
  }

  // 1. Auth Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/customer/register';
  static String get me => '$baseUrl/auth/me';
  static String get logout => '$baseUrl/auth/logout';

  // 2. Menu & Banners Endpoints
  static String get products => '$baseUrl/products';
  static String get banners => '$baseUrl/banners';

  // 3. Orders Endpoints
  static String get orders => '$baseUrl/orders';
  static String get trackOrders => '$baseUrl/orders/track';
  static String get customerOrders => '$baseUrl/customer/orders';

  // 4. Vouchers Endpoints
  static String get validateVoucher => '$baseUrl/vouchers/validate';
  static String get customerVouchers => '$baseUrl/customer/vouchers';

  // 5. Waiter Call Endpoints (QR In-House)
  static String get waiterCall => '$baseUrl/waiter-call';
  static String get waiterCallStatus => '$baseUrl/waiter-call/status';
}

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
  static String get me {
    if (baseUrl.contains('/api/v1')) {
      return baseUrl.replaceFirst('/api/v1', '/api/user');
    }
    return '$baseUrl/user';
  }
  static String get logout => '$baseUrl/auth/logout';
  static String get forgotPassword => '$baseUrl/customer/forgot-password';
  static String get resetPassword => '$baseUrl/customer/reset-password';

  /// Alternate paths used by some backend deploys
  static String get forgotPasswordAlt => '$baseUrl/customer/forgot';
  static String get resetPasswordAlt => '$baseUrl/customer/reset';
  static String get forgotPasswordAuth => '$baseUrl/auth/forgot-password';
  static String get resetPasswordAuth => '$baseUrl/auth/reset-password';
  static String get googleLogin => '$baseUrl/auth/google';
  static String get verifyEmail => '$baseUrl/auth/verify-email';
  static String get resendVerification => '$baseUrl/auth/resend-verification';

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

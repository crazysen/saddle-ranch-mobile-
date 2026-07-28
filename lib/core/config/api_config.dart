class ApiConfig {
  /// Toggle bypassBackend to true for zero-latency UI development & testing without waiting for backend/Render API timeouts.
  static bool bypassBackend = true;

  /// Default Render backend base URL
  static const String defaultRenderUrl = 'https://saddle-ranch-api.onrender.com/api/v1';

  /// Override base URL for custom deployment or testing.
  static String? overrideBaseUrl;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    return defaultRenderUrl;
  }

  static String get products => '$baseUrl/products';
  static String get banners => '$baseUrl/banners';
  static String get orders => '$baseUrl/orders';
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
  static String get logout => '$baseUrl/auth/logout';
  static String get validateVoucher => '$baseUrl/vouchers/validate';
}

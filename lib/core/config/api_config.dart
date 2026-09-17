import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Toggle bypassBackend to true only for offline fallback/testing.
  /// Set to false to connect directly to the live Laravel database hosted on Render.
  static bool bypassBackend = false;

  /// Live Render backend base URL
  static const String defaultRenderUrl = 'https://saddle-ranch-web.onrender.com/api/v1';

  /// Local development backend base URL (Laravel server)
  static const String localBackendUrl = 'http://127.0.0.1:8000/api/v1';

  /// Optional override for local development or custom environment
  static String? overrideBaseUrl;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Automatically connect to local Laravel server when running in browser on localhost or 127.0.0.1
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') {
        return localBackendUrl;
      }
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

  /// Alternate paths used by different backend deploys
  static String get forgotPasswordAlt => '$baseUrl/customer/forgot';
  static String get forgotPasswordAuth => '$baseUrl/auth/forgot-password';
  static String get forgotPasswordAuthAlt => '$baseUrl/auth/forgot';
  static String get forgotPasswordCustomPassword => '$baseUrl/customer/password/forgot';
  static String get forgotPasswordAuthPassword => '$baseUrl/auth/password/forgot';

  static String get resetPasswordAlt => '$baseUrl/customer/reset';
  static String get resetPasswordAuth => '$baseUrl/auth/reset-password';
  static String get resetPasswordAuthAlt => '$baseUrl/auth/reset';
  static String get resetPasswordCustomPassword => '$baseUrl/customer/password/reset';
  static String get resetPasswordAuthPassword => '$baseUrl/auth/password/reset';

  static String get googleLogin => '$baseUrl/auth/google';

  static String get verifyEmail => '$baseUrl/auth/verify-email';
  static String get verifyEmailCustomer => '$baseUrl/customer/verify-email';
  static String get verifyEmailAuth => '$baseUrl/auth/verify';
  static String get verifyEmailCustomerAlt => '$baseUrl/customer/verify';
  static String get verifyEmailAuthEmail => '$baseUrl/auth/email/verify';
  static String get verifyEmailCustomerEmail => '$baseUrl/customer/email/verify';

  static String get resendVerification => '$baseUrl/auth/resend-verification';
  static String get resendVerificationCustomer => '$baseUrl/customer/resend-verification';
  static String get resendVerificationAuth => '$baseUrl/auth/resend';
  static String get resendVerificationCustomerAlt => '$baseUrl/customer/resend';
  static String get resendVerificationAuthEmail => '$baseUrl/auth/email/resend';
  static String get resendVerificationCustomerEmail => '$baseUrl/customer/email/resend';

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

  // 6. Table session lock / unlock (staff-controlled dine-in)
  static String tableSession(String tableNumber) =>
      '$baseUrl/table-sessions/${Uri.encodeComponent(tableNumber)}';
  static String get tableUnlockRequest => '$baseUrl/table-unlock-request';
  static String get tableUnlockRequestStatus => '$baseUrl/table-unlock-request/status';
}

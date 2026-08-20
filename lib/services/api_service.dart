import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/app_user.dart';
import '../models/order_result.dart';
import '../models/product.dart';
import '../models/promo_banner.dart';
import '../models/voucher.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  static const String _tokenStorageKey = 'sanctum_bearer_token';
  final http.Client _client;
  final FlutterSecureStorage _storage;

  ApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  /// Retrieve stored Sanctum Bearer token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenStorageKey);
    } catch (_) {
      return null;
    }
  }

  /// Store Sanctum Bearer token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenStorageKey, value: token);
  }

  /// Clear stored token
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenStorageKey);
  }

  /// Automatic headers injector appending `Authorization: Bearer <token>` and `Accept: application/json`
  Future<Map<String, String>> _buildHeaders({Map<String, String>? extraHeaders}) async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  // ==========================================
  // 1. AUTHENTICATION ENDPOINTS
  // ==========================================

  /// POST /auth/login - Sanctum authentication against live database
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final headers = await _buildHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.login),
      headers: headers,
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = body['token'] ?? body['access_token'] ?? body['data']?['token'];
      if (token != null && token.toString().isNotEmpty) {
        await saveToken(token.toString());
      }
      return body;
    }

    String errorMessage = body['message']?.toString() ?? 'Invalid login credentials.';
    if (body['errors'] is Map<String, dynamic>) {
      final errMap = body['errors'] as Map<String, dynamic>;
      final firstKey = errMap.keys.firstOrNull;
      if (firstKey != null && errMap[firstKey] is List && (errMap[firstKey] as List).isNotEmpty) {
        errorMessage = (errMap[firstKey] as List).first.toString();
      }
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      errors: body['errors'] is Map<String, dynamic> ? body['errors'] as Map<String, dynamic> : null,
    );
  }

  /// POST /customer/register - Customer registration in database
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final headers = await _buildHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.register),
      headers: headers,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null && phone.trim().isNotEmpty) 'phone_number': phone.trim(),
      }),
    );

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = body['message']?.toString() ?? 'Registration failed.';
    if (body['errors'] is Map<String, dynamic>) {
      final errMap = body['errors'] as Map<String, dynamic>;
      final firstKey = errMap.keys.firstOrNull;
      if (firstKey != null && errMap[firstKey] is List && (errMap[firstKey] as List).isNotEmpty) {
        errorMessage = (errMap[firstKey] as List).first.toString();
      }
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      errors: body['errors'] is Map<String, dynamic> ? body['errors'] as Map<String, dynamic> : null,
    );
  }

  /// GET /api/user - Fetch authenticated user profile details from database
  Future<AppUser> getProfile() async {
    final headers = await _buildHeaders();
    final response = await _client.get(
      Uri.parse(ApiConfig.me),
      headers: headers,
    );

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final userData = (body['user'] ?? body['data'] ?? body) as Map<String, dynamic>;
      return AppUser.fromJson(userData);
    }

    // Fallback attempt to customer/me if available
    try {
      final fallbackResp = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/customer/me'),
        headers: headers,
      );
      final fbBody = _decode(fallbackResp);
      if (fallbackResp.statusCode >= 200 && fallbackResp.statusCode < 300 && fbBody['user'] != null) {
        return AppUser.fromJson(fbBody['user'] as Map<String, dynamic>);
      }
    } catch (_) {}

    throw ApiException(
      body['message']?.toString() ?? 'Failed to fetch user profile.',
      statusCode: response.statusCode,
    );
  }

  /// POST /auth/logout - Revoke Sanctum Bearer token
  Future<void> logout() async {
    try {
      final headers = await _buildHeaders();
      await _client.post(
        Uri.parse(ApiConfig.logout),
        headers: headers,
      );
    } catch (_) {
      // Ignore API errors during logout
    } finally {
      await clearToken();
    }
  }

  // ==========================================
  // 2. MENU & PROMOTIONS ENDPOINTS
  // ==========================================

  /// GET /products - Fetch active menu products directly from database
  Future<List<Product>> fetchProducts() async {
    final headers = await _buildHeaders();
    final response = await _client.get(
      Uri.parse(ApiConfig.products),
      headers: headers,
    );
    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();
    }
    throw ApiException(
      body['message']?.toString() ?? 'Failed to load products from database.',
      statusCode: response.statusCode,
    );
  }

  /// GET /banners - Fetch promotional banners directly from database
  Future<List<PromoBanner>> fetchBanners() async {
    final headers = await _buildHeaders();
    final response = await _client.get(
      Uri.parse(ApiConfig.banners),
      headers: headers,
    );
    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => PromoBanner.fromJson(e as Map<String, dynamic>))
          .where((b) => b.isActive)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    throw ApiException(
      body['message']?.toString() ?? 'Failed to load banners from database.',
      statusCode: response.statusCode,
    );
  }

  // ==========================================
  // 3. VOUCHER VALIDATION & LISTING
  // ==========================================

  /// POST /vouchers/validate - Validate coupon code directly against database discount engine
  Future<Map<String, dynamic>> validateVoucher({
    required String code,
    required double subtotal,
    String branch = 'Bulihan',
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final branchKey = branch.toLowerCase();

    try {
      final headers = await _buildHeaders();
      final response = await _client.post(
        Uri.parse(ApiConfig.validateVoucher),
        headers: headers,
        body: jsonEncode({
          'code': cleanCode,
          'subtotal': subtotal,
          'total_amount': subtotal,
          'branch': branchKey,
        }),
      );

      final body = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }

      if (response.statusCode != 401 &&
          body['message'] != null &&
          !body['message'].toString().toLowerCase().contains('logged in') &&
          !body['message'].toString().toLowerCase().contains('total amount')) {
        throw ApiException(
          body['message'].toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException &&
          !e.message.toLowerCase().contains('logged in') &&
          !e.message.toLowerCase().contains('total amount')) {
        rethrow;
      }
    }

    // Fallback: Validate directly against live database vouchers list
    final allVouchers = await fetchCustomerVouchers();
    final match = allVouchers.where((v) => v.code.toUpperCase() == cleanCode).firstOrNull;
    if (match == null) {
      throw ApiException('Invalid promo coupon code.');
    }

    if (match.branch != 'all' &&
        !match.branch.toLowerCase().contains(branchKey) &&
        !branchKey.contains(match.branch.toLowerCase())) {
      throw ApiException('This voucher is only valid for ${match.branch.toUpperCase()} branch.');
    }

    if (subtotal < match.minSpend) {
      throw ApiException('Minimum spend of ₱${match.minSpend.toStringAsFixed(0)} is required for this voucher.');
    }

    return {
      'status': 'success',
      'message': 'Voucher applied successfully!',
      'voucher': match.toJson(),
      'discount': match.calculateDiscount(subtotal),
    };
  }

  /// GET /customer/vouchers - Available vouchers for authenticated user from database
  Future<List<Voucher>> fetchCustomerVouchers() async {
    try {
      final headers = await _buildHeaders();
      final response = await _client.get(
        Uri.parse(ApiConfig.customerVouchers),
        headers: headers,
      );
      final body = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (body['data'] ?? body['vouchers'] ?? body) as List<dynamic>? ?? [];
        return list.map((v) => Voucher.fromJson(v as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 4. ORDERS & TRACKING
  // ==========================================

  static final List<OrderResult> _localPlacedOrders = [];

  /// POST /orders - Place new order into live database
  Future<OrderResult> placeOrder({
    required String orderType,
    String branch = 'Bulihan',
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryNotes,
    String? voucherCode,
    double? discountAmount,
  }) async {
    final headers = await _buildHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.orders),
      headers: headers,
      body: jsonEncode({
        'order_type': orderType,
        'branch': branch,
        'payment_method': paymentMethod,
        'items': items,
        if (tableNumber != null && tableNumber.isNotEmpty) 'table_number': tableNumber,
        if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
        if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
        if (deliveryAddress != null && deliveryAddress.isNotEmpty) 'delivery_address': deliveryAddress,
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) 'delivery_notes': deliveryNotes,
        if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
        if (discountAmount != null && discountAmount > 0) 'discount_amount': discountAmount,
      }),
    );

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final order = OrderResult.fromJson(data);
      // Ensure created_at is present for real-time tracking
      final completeOrder = order.createdAt == null || order.createdAt!.isEmpty
          ? order.copyWith(createdAt: DateTime.now().toUtc().toIso8601String())
          : order;
      _localPlacedOrders.removeWhere((o) => o.orderNumber == completeOrder.orderNumber);
      _localPlacedOrders.insert(0, completeOrder);
      return completeOrder;
    }

    throw ApiException(
      body['message']?.toString() ?? 'Failed to place order in database.',
      statusCode: response.statusCode,
      errors: body['errors'] is Map<String, dynamic> ? body['errors'] as Map<String, dynamic> : null,
    );
  }

  /// GET /orders/track?query=... - Track active orders directly from live database (Web Admin/POS/KDS state)
  Future<List<OrderResult>> trackOrders({String? query, bool all = false}) async {
    final results = <OrderResult>[];
    try {
      final headers = await _buildHeaders();

      // If no query is provided, query all or include placed order numbers
      String? effectiveQuery = query;
      if ((effectiveQuery == null || effectiveQuery.isEmpty) && !all && _localPlacedOrders.isNotEmpty) {
        effectiveQuery = _localPlacedOrders.map((o) => o.orderNumber).join(',');
      }

      final uri = Uri.parse(ApiConfig.trackOrders).replace(
        queryParameters: {
          if (effectiveQuery != null && effectiveQuery.isNotEmpty) 'query': effectiveQuery,
          if (all || effectiveQuery == null || effectiveQuery.isEmpty) 'all': '1',
        },
      );

      final response = await _client.get(uri, headers: headers);
      final body = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (body['data'] ?? body['orders'] ?? body) as List<dynamic>? ?? [];
        final fetched = list.map((o) => OrderResult.fromJson(o as Map<String, dynamic>)).toList();
        results.addAll(fetched);

        // Update local cache with live database statuses from Web Admin / KDS / Cashier
        for (final item in fetched) {
          final idx = _localPlacedOrders.indexWhere((o) => o.orderNumber == item.orderNumber);
          if (idx >= 0) {
            _localPlacedOrders[idx] = item;
          }
        }
      }
    } catch (_) {}

    // Include any local placed orders if not yet returned in search filter
    for (final local in _localPlacedOrders) {
      if (!results.any((r) => r.orderNumber == local.orderNumber)) {
        if (query == null ||
            query.isEmpty ||
            local.orderNumber.toLowerCase().contains(query.toLowerCase()) ||
            (local.customerPhone != null && local.customerPhone!.contains(query))) {
          results.add(local);
        }
      }
    }

    // Sort results by ID descending so newest orders appear at top
    results.sort((a, b) => b.id.compareTo(a.id));
    return results;
  }

  /// GET /customer/orders - Historical orders for logged-in user from database
  Future<List<OrderResult>> fetchCustomerOrders() async {
    try {
      final headers = await _buildHeaders();
      final response = await _client.get(
        Uri.parse(ApiConfig.customerOrders),
        headers: headers,
      );
      final body = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (body['data'] ?? body['orders'] ?? body) as List<dynamic>? ?? [];
        return list.map((o) => OrderResult.fromJson(o as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 5. WAITER CALL BUZZER (QR In-House)
  // ==========================================

  /// POST /waiter-call - Buzz for assistance in live database/cache
  Future<void> callWaiter({required String tableNumber, String branch = 'Bulihan'}) async {
    final headers = await _buildHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.waiterCall),
      headers: headers,
      body: jsonEncode({
        'table_number': tableNumber,
        'branch': branch,
      }),
    );

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ApiException(
      body['message']?.toString() ?? 'Unable to send waiter buzzer signal.',
      statusCode: response.statusCode,
    );
  }

  /// GET /waiter-call/status?table_number=... - Poll waiter buzzer status from database
  Future<String> getWaiterCallStatus({required String tableNumber}) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(ApiConfig.waiterCallStatus).replace(
        queryParameters: {'table_number': tableNumber},
      );
      final response = await _client.get(uri, headers: headers);
      final body = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body['data'] as Map<String, dynamic>? ?? body;
        return (data['status'] ?? 'idle').toString();
      }
      return 'idle';
    } catch (_) {
      return 'idle';
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'message': response.body};
    }
  }
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/app_user.dart';
import '../models/order_result.dart';
import '../models/product.dart';
import '../models/promo_banner.dart';

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

  /// POST /auth/login - Sanctum authentication
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (ApiConfig.bypassBackend) {
      final mockToken = 'mock_sanctum_token_${DateTime.now().millisecondsSinceEpoch}';
      await saveToken(mockToken);
      return {
        'token': mockToken,
        'token_type': 'Bearer',
        'user': {
          'name': email.split('@').first.toUpperCase(),
          'email': email.trim(),
          'phone': '09171234567',
        },
      };
    }

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

    throw ApiException(
      body['message']?.toString() ?? 'Invalid login credentials.',
      statusCode: response.statusCode,
      errors: body['errors'] is Map<String, dynamic> ? body['errors'] as Map<String, dynamic> : null,
    );
  }

  /// POST /auth/register - Customer registration
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    if (ApiConfig.bypassBackend) {
      final mockToken = 'mock_sanctum_token_${DateTime.now().millisecondsSinceEpoch}';
      await saveToken(mockToken);
      return {
        'token': mockToken,
        'token_type': 'Bearer',
        'user': {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone?.trim(),
        },
      };
    }

    final headers = await _buildHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.register),
      headers: headers,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
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

    throw ApiException(
      body['message']?.toString() ?? 'Registration failed.',
      statusCode: response.statusCode,
      errors: body['errors'] is Map<String, dynamic> ? body['errors'] as Map<String, dynamic> : null,
    );
  }

  /// GET /auth/me - Fetch authenticated user profile details
  Future<AppUser> getProfile() async {
    if (ApiConfig.bypassBackend) {
      return const AppUser(
        email: 'customer@saddleranch.ph',
        fullName: 'Juan Dela Cruz',
        phone: '09171234567',
        profileComplete: true,
      );
    }

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

    throw ApiException(
      body['message']?.toString() ?? 'Failed to fetch user profile.',
      statusCode: response.statusCode,
    );
  }

  /// POST /auth/logout - Revoke Sanctum Bearer token
  Future<void> logout() async {
    if (ApiConfig.bypassBackend) {
      await clearToken();
      return;
    }

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

  /// Fetch menu products
  Future<List<Product>> fetchProducts() async {
    if (ApiConfig.bypassBackend) {
      return _fallbackProducts;
    }

    try {
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
        body['message']?.toString() ?? 'Failed to load products.',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      return _fallbackProducts;
    }
  }

  /// Fetch promotional banners
  Future<List<PromoBanner>> fetchBanners() async {
    if (ApiConfig.bypassBackend) {
      return _fallbackBanners;
    }

    try {
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
        body['message']?.toString() ?? 'Failed to load banners.',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      return _fallbackBanners;
    }
  }

  /// Submit an order
  Future<OrderResult> placeOrder({
    required String orderType,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryNotes,
  }) async {
    if (ApiConfig.bypassBackend) {
      final now = DateTime.now().millisecondsSinceEpoch;
      double total = 0;
      for (final item in items) {
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        total += price * qty;
      }
      return OrderResult(
        id: now % 100000,
        orderNumber: 'SR-${(now % 10000).toString().padLeft(4, '0')}',
        status: 'pending',
        orderType: orderType,
        paymentMethod: paymentMethod,
        totalAmount: total,
        tableNumber: tableNumber,
      );
    }

    final headers = await _buildHeaders();
    final response = await _client.post(
      Uri.parse(ApiConfig.orders),
      headers: headers,
      body: jsonEncode({
        'order_type': orderType,
        'payment_method': paymentMethod,
        'items': items,
        if (tableNumber != null && tableNumber.isNotEmpty) 'table_number': tableNumber,
        if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
        if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
        if (deliveryAddress != null && deliveryAddress.isNotEmpty)
          'delivery_address': deliveryAddress,
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) 'delivery_notes': deliveryNotes,
      }),
    );

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return OrderResult.fromJson(data);
    }

    throw ApiException(
      body['message']?.toString() ?? 'Failed to place order.',
      statusCode: response.statusCode,
    );
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

const _fallbackBanners = [
  PromoBanner(
    id: 1,
    title: 'Weekend Sizzling Specials',
    subtitle: 'Up to 15% off barkada platters',
    badge: 'Hot',
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuASVSO6N3lzIbdlCDT85viSxOZiQKjWADlA5k7ymludjTdSCB7tqV0bZvXRba3-L4gemLyqy9PxmqnYMBnSsxb5yfI_XM-qajS5ZEnS1Am8OBu5uN8_smBFlDdy4xR0UNE8jDFJP8vNSRQcqqDSG4p-oDij5kCvWALcyBZVeuA1QdnqC9a6I5s9l2ba3Zjfe0xSPjMr0jLCAB1z-oJS5xBL9meeUeFsmiMgjQ96VoXotgHsy3Jl3d9NQIv1liJsKeu_sJec2rrkNziY',
    isActive: true,
    displayOrder: 1,
  ),
  PromoBanner(
    id: 2,
    title: 'Sisig Night Combo',
    subtitle: 'Free iced tea on ₱499+',
    badge: 'Deal',
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDt2cP7W6u7Hw-wJCWrbYiEh20Z4b79UCpbKxmmyVbQzw0xlTklDnEKOpEzeymppd9l-ODs0TOelRWM0iLgwF8K_OKfXIBpTO8lSH0yyxPtaMCTQrzQ4ykSkJPDryw9S9IBB1wNoeHFGtHcQDy4MEVr0_tUDss7SKe1fe58XBlXeql1nJ1D2J0zJ0ZFO4qRm213kO813mLEdYdUMjsTD0J2PtB7cz_0FmmDHccmacBmhMyp7a_fJ7teNVsG3sgWyfW24O1p08mnUE9t',
    isActive: true,
    displayOrder: 2,
  ),
  PromoBanner(
    id: 3,
    title: 'Bulalo Steak Feast',
    subtitle: 'Share for 2–3 people',
    badge: 'New',
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCatSLXJ-mynm_AwjLXsdG9xKbMwziehShgiNtyXaX2NZEeZFhSXaTmHMgLuACAitSC3WZ0g_9lSTavvnqO4eKFlaC0pnnA9OngEMtRicl0vfSF2_t4WqzxTKxW-H-X0i_tppiClzEOZ-fAuu1ezCbRVOcdVdwZHokttY1ATDIO4BuA185dwrm0QDuPpYjQ7qD9ybH5bl0WPn1wHJ3S5pB6JuCOoocWTfZ95cB0Lfqx1KbjbUwqGJxkhwxmqypEJta64yq1PajT3oWC',
    isActive: true,
    displayOrder: 3,
  ),
];

const _fallbackProducts = [
  Product(
    id: 1,
    name: 'Sizzling Pork Sisig',
    description: 'Crispy pork belly with local spices and egg on a hot plate.',
    price: 180,
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDt2cP7W6u7Hw-wJCWrbYiEh20Z4b79UCpbKxmmyVbQzw0xlTklDnEKOpEzeymppd9l-ODs0TOelRWM0iLgwF8K_OKfXIBpTO8lSH0yyxPtaMCTQrzQ4ykSkJPDryw9S9IBB1wNoeHFGtHcQDy4MEVr0_tUDss7SKe1fe58XBlXeql1nJ1D2J0zJ0ZFO4qRm213kO813mLEdYdUMjsTD0J2PtB7cz_0FmmDHccmacBmhMyp7a_fJ7teNVsG3sgWyfW24O1p08mnUE9t',
    stockQuantity: 50,
    isActive: true,
  ),
  Product(
    id: 2,
    name: 'Sizzling Pork T-Bone Steak',
    description: 'Tender T-Bone steak with signature gravy.',
    price: 280,
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuASVSO6N3lzIbdlCDT85viSxOZiQKjWADlA5k7ymludjTdSCB7tqV0bZvXRba3-L4gemLyqy9PxmqnYMBnSsxb5yfI_XM-qajS5ZEnS1Am8OBu5uN8_smBFlDdy4xR0UNE8jDFJP8vNSRQcqqDSG4p-oDij5kCvWALcyBZVeuA1QdnqC9a6I5s9l2ba3Zjfe0xSPjMr0jLCAB1z-oJS5xBL9meeUeFsmiMgjQ96VoXotgHsy3Jl3d9NQIv1liJsKeu_sJec2rrkNziY',
    stockQuantity: 30,
    isActive: true,
  ),
  Product(
    id: 3,
    name: 'Sizzling Bulalo Steak',
    description: 'Rich beef shank with simmering bone marrow gravy.',
    price: 450,
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCatSLXJ-mynm_AwjLXsdG9xKbMwziehShgiNtyXaX2NZEeZFhSXaTmHMgLuACAitSC3WZ0g_9lSTavvnqO4eKFlaC0pnnA9OngEMtRicl0vfSF2_t4WqzxTKxW-H-X0i_tppiClzEOZ-fAuu1ezCbRVOcdVdwZHokttY1ATDIO4BuA185dwrm0QDuPpYjQ7qD9ybH5bl0WPn1wHJ3S5pB6JuCOoocWTfZ95cB0Lfqx1KbjbUwqGJxkhwxmqypEJta64yq1PajT3oWC',
    stockQuantity: 15,
    isActive: true,
  ),
  Product(
    id: 4,
    name: 'Sizzling Chicken Inasal',
    description: 'Chargrilled Bacolod-style chicken with garlic rice.',
    price: 220,
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB6QEUONokTX7mi1M1Wrie14cxeoNfVq5HyIS1sLOLWKbzZyh6OfegCBaNeH6E7uS37ugVc6jjmILNzIrmvE0tpXkOBCDP29HO1WZL69MsOd6lpwp4oX6ezfDjuAsLMCu57vBpiHDupWu3yDATuk2k_HgpQMi23Y7mifgQKqPJhc0GqDXCCk1tPooIkFyBCXPiESBHm8HKF8cp1ctvD0RZ39YNVxKG_2cPaPyfryUGBbaoIHhqqhq5R9BflPtI6jMfzsP3W6QStlttx',
    stockQuantity: 40,
    isActive: true,
  ),
  Product(
    id: 5,
    name: 'Sizzling Beef Pepper Rice',
    description: 'Peppery beef strips over garlic rice on cast iron.',
    price: 195,
    stockQuantity: 35,
    isActive: true,
  ),
  Product(
    id: 6,
    name: 'Sizzling Chicken Inasal Platter',
    description: 'Sharing platter of inasal for the barkada.',
    price: 520,
    stockQuantity: 20,
    isActive: true,
  ),
  Product(
    id: 7,
    name: 'Sizzling Gambas Al Ajillo',
    description: 'Garlic shrimp sizzler made for sharing.',
    price: 320,
    stockQuantity: 25,
    isActive: true,
  ),
  Product(
    id: 8,
    name: 'Signature Red Iced Tea (1L)',
    description: 'Chilled house-brewed red iced tea pitcher.',
    price: 95,
    imagePath:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuMIwhrcJTtw4asxssNVZ2VWGxMaovy2G1K8R0Ix8yDYIZmMquCCDp47-9iSZeRJZPGoqUA_gstmSpYFxDQdS1nDIkmXqLfi-tQLTneA4ORWkxGtLYbCbkjLJ2sZcAuvum0fGxFxM8i2GzRSAaFKYWHdOIp6HsbA9GRrg84sBVlnpzrm4YyuS53vG9_x_SOV-OQNPEsIkecPojkMz-8yFDwZ07jXZ3SnUf-A_tEyuljflrAP4mCwWgHiFNvHAbJt-LBV66MAiCwKl',
    stockQuantity: 100,
    isActive: true,
  ),
  Product(
    id: 9,
    name: 'Extra Garlic Rice',
    description: 'Extra serving of toasted garlic rice.',
    price: 45,
    stockQuantity: 100,
    isActive: true,
  ),
];

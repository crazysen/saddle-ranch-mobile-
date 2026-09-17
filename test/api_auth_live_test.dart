import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saddle_ranch_mobile/services/api_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterSecureStorage.setMockInitialValues({});

  test('Live Register and Login test against Render Laravel API', () async {
    final api = ApiService();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'juan_test_$timestamp@saddleranch.ph';
    final password = 'Password123!';

    // 1. Test Register (unverified account returns requires_email_verification)
    final regResponse = await api.register(
      name: 'Juan Dela Cruz',
      email: email,
      password: password,
      passwordConfirmation: password,
      phone: '09171234567',
    );

    expect(regResponse, isNotNull);
    expect(regResponse['status'] == 'success' || regResponse['user'] != null, isTrue);

    // 2. Test Login (new accounts require email verification code and throw ApiException)
    try {
      final loginResponse = await api.login(
        email: email,
        password: password,
      );
      // In case pre-verified on server
      expect(loginResponse, isNotNull);
    } on ApiException catch (e) {
      expect(e.requiresEmailVerification, isTrue);
    }
  });
}

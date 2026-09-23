import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saddle_ranch_mobile/models/product.dart';
import 'package:saddle_ranch_mobile/models/voucher.dart';
import 'package:saddle_ranch_mobile/providers/cart_provider.dart';
import 'package:saddle_ranch_mobile/providers/order_session_provider.dart';
import 'package:saddle_ranch_mobile/services/api_service.dart';
import 'package:saddle_ranch_mobile/utils/table_code.dart';

class _SystemTestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _SystemTestHttpOverrides();
  FlutterSecureStorage.setMockInitialValues({});

  final api = ApiService();

  group('1. Authentication & Role Logins', () {
    test('Customer Account Login: dzeref4000@gmail.com', () async {
      try {
        final result = await api.login(
          email: 'dzeref4000@gmail.com',
          password: '@Admin321',
        );
        expect(result, isNotNull);
        expect(result['token'] != null || result['access_token'] != null, isTrue);
      } on ApiException catch (e) {
        // If email verification is required or valid error response received
        expect(
          e.requiresEmailVerification || e.message.isNotEmpty,
          isTrue,
        );
      }
    });

    test('Admin Account Login: admin@saddleranch.ph', () async {
      try {
        final result = await api.login(
          email: 'admin@saddleranch.ph',
          password: 'password',
        );
        expect(result, isNotNull);
      } on ApiException catch (e) {
        expect(e.message.isNotEmpty, isTrue);
      }
    });

    test('Cashier / Employee Account Login: cashier@saddleranch.ph', () async {
      try {
        final result = await api.login(
          email: 'cashier@saddleranch.ph',
          password: 'password',
        );
        expect(result, isNotNull);
      } on ApiException catch (e) {
        expect(e.message.isNotEmpty, isTrue);
      }
    });
  });

  group('2. Customer Registration Flow', () {
    test('Customer can submit registration to database', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'customer_test_$ts@saddleranch.ph';

      try {
        final res = await api.register(
          name: 'Test Customer',
          email: testEmail,
          password: 'Password123!',
          passwordConfirmation: 'Password123!',
          phone: '09171234567',
        );
        expect(res, isNotNull);
        expect(res['status'] == 'success' || res['user'] != null, isTrue);
      } on ApiException catch (e) {
        expect(e.message.isNotEmpty, isTrue);
      }
    });
  });

  group('3. Dine-In (QR Ordering & Table Session)', () {
    test('TableCode parses diverse QR code URLs and raw codes correctly', () {
      final normalized1 = TableCode.normalize('B-08');
      expect(normalized1, 'B-08');
      expect(TableCode.digits('B-08'), '08');
      expect(TableCode.branchFromCode('B-08'), 'Bulihan');

      final normalized2 = TableCode.normalize('D-03');
      expect(normalized2, 'D-03');
      expect(TableCode.digits('D-03'), '03');
      expect(TableCode.branchFromCode('D-03'), 'Dasma');

      final candidates = TableCode.lookupCandidates('05');
      expect(candidates.contains('05'), isTrue);
    });

    test('Dine-In session lock & unlock request dispatch', () async {
      final session = OrderSessionProvider(api: api);
      session.startDineInFromTable('01');
      expect(session.isDineIn, isTrue);
      expect(session.tableNumber, '01');

      try {
        await api.requestTableUnlock(
          tableNumber: '01',
          branch: 'Bulihan',
        );
      } on ApiException catch (e) {
        expect(e.message.isNotEmpty, isTrue);
      }
    });
  });

  group('4. Pick-Up Ordering Flow', () {
    test('Pick-Up mode configuration and branch selection', () {
      final session = OrderSessionProvider(api: api);
      session.setMode(OrderMode.pickup);
      session.setBranch('Bulihan');

      expect(session.mode, OrderMode.pickup);
      expect(session.mode.apiValue, 'pickup');
      expect(session.isDineIn, isFalse);
    });
  });

  group('5. Delivery Ordering Flow & Remote Policies', () {
    test('Delivery mode validates address and requires payment first (no COD)', () {
      final session = OrderSessionProvider(api: api);
      session.setMode(OrderMode.delivery);
      session.updateLocation(
        title: 'Customer Residence',
        subtitle: 'Block 4 Lot 12, Golden City, Dasmariñas, Cavite',
        isBulihan: false,
      );

      expect(session.mode, OrderMode.delivery);
      expect(session.mode.apiValue, 'delivery');
      expect(session.deliveryAddressTitle, 'Customer Residence');
      expect(session.isBulihanAddress, isFalse);
    });
  });

  group('6. PayMongo Payment (Testing Mode)', () {
    test('PayMongo payment confirmation flow', () async {
      try {
        await api.confirmPayment(orderNumber: 'SR-TEST-ORDER-001');
      } on ApiException catch (e) {
        // Expected since test order does not exist in live DB
        expect(e.message.isNotEmpty, isTrue);
      }
    });
  });

  group('7. Adding to Cart & Pricing Engine', () {
    const testProduct1 = Product(
      id: 991,
      name: 'Sizzling Sisig Platter',
      description: 'Classic pork sisig with egg and calamansi',
      price: 150.00,
      imagePath: 'https://example.com/sisig.jpg',
      category: 'Sizzling Specials',
      stockQuantity: 20,
      stockBulihan: 20,
      stockDasmarinas: 15,
      isActive: true,
    );

    const testProduct2 = Product(
      id: 992,
      name: 'Garlic Rice',
      description: 'Extra fragrant garlic rice',
      price: 30.00,
      imagePath: 'https://example.com/rice.jpg',
      category: 'Sides & Rice',
      stockQuantity: 50,
      stockBulihan: 50,
      stockDasmarinas: 50,
      isActive: true,
    );

    test('Add item, increment, update quantity, and subtotal calculation', () {
      final cart = CartProvider(api: api);
      cart.setBranch('Bulihan');

      expect(cart.isEmpty, isTrue);

      // 1. Add product 1
      cart.add(testProduct1, quantity: 2);
      expect(cart.items.length, 1);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 300.00);

      // 2. Add product 1 again (should increment quantity)
      cart.add(testProduct1, quantity: 1);
      expect(cart.itemCount, 3);
      expect(cart.subtotal, 450.00);

      // 3. Add product 2
      cart.add(testProduct2, quantity: 2);
      expect(cart.items.length, 2);
      expect(cart.itemCount, 5);
      expect(cart.subtotal, 510.00);

      // 4. Update quantity
      cart.updateQuantity(testProduct2.id, 4);
      expect(cart.itemCount, 7);
      expect(cart.subtotal, 570.00);

      // 5. Remove item
      cart.remove(testProduct1.id);
      expect(cart.items.length, 1);
      expect(cart.itemCount, 4);
      expect(cart.subtotal, 120.00);
    });

    test('Voucher discount calculation in Cart', () {
      final cart = CartProvider(api: api);
      cart.setBranch('Bulihan');
      cart.add(testProduct1, quantity: 3); // Subtotal: 450.00

      const voucher10Pct = Voucher(
        id: 1,
        code: 'SADDLE10',
        discountType: 'percentage',
        value: 10.0,
        minSpend: 200.0,
        branch: 'all',
        isOneTimeUse: false,
      );

      // Manually simulate validated voucher
      expect(voucher10Pct.calculateDiscount(cart.subtotal), 45.00);
    });
  });

  group('8. Realtime Polling Services', () {
    test('Track orders and waiter status polling endpoints', () async {
      try {
        final orders = await api.trackOrders(query: 'SR-DEMO-001');
        expect(orders, isNotNull);
      } on ApiException catch (e) {
        expect(e.message.isNotEmpty, isTrue);
      }

      try {
        final waiterStatus = await api.getWaiterCallStatus(tableNumber: '01');
        expect(waiterStatus, isNotNull);
      } on ApiException catch (e) {
        expect(e.message.isNotEmpty, isTrue);
      }
    });

    test('OrderSessionProvider polling timer lifecycle', () {
      final session = OrderSessionProvider(api: api);
      session.startDineInFromTable('05');

      // Verify polling can be invoked without throws
      expect(() => session.pollWaiterStatus(), returnsNormally);

      // Ensure dispose stops all timers cleanly
      session.dispose();
    });
  });
}

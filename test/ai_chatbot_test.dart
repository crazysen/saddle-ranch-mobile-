import 'package:flutter_test/flutter_test.dart';
import 'package:saddle_ranch_mobile/widgets/ai_chatbot_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saddle_ranch_mobile/providers/order_session_provider.dart';
import 'package:saddle_ranch_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Chatbot Modal Tests', () {
    testWidgets('Renders Help Assistant modal structure correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OrderSessionProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiChatbotModal(currentBranch: 'Bulihan'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check header title and logo image
      expect(find.text('Help Assistant'), findsAtLeast(1));
      expect(find.byType(Image), findsOneWidget);

      // Check quick chips (with skipOffstage for horizontal scroll)
      expect(find.text('📦 Track Order'), findsOneWidget);
      expect(find.text('📍 Locations'), findsOneWidget);
      expect(find.text('🕒 Hours'), findsOneWidget);
      expect(find.text('🥩 Menu & Prices'), findsOneWidget);
      expect(find.text('🎉 Promos', skipOffstage: false), findsOneWidget);
      expect(find.text('🎟️ Vouchers', skipOffstage: false), findsOneWidget);

      // Check text input field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Submitting order question triggers order tracking response', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OrderSessionProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiChatbotModal(currentBranch: 'Bulihan'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Enter order inquiry into textfield and submit
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'can you track my order?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // User message should appear
      expect(find.text('can you track my order?'), findsOneWidget);

      // Advance clock past the response delay and typewriter
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(seconds: 2));

      // Bot responds with order tracking guidance or order info
      expect(find.textContaining('Order'), findsAtLeast(1));
    });
  });
}


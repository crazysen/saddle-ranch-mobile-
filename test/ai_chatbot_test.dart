import 'package:flutter_test/flutter_test.dart';
import 'package:saddle_ranch_mobile/widgets/ai_chatbot_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saddle_ranch_mobile/providers/order_session_provider.dart';
import 'package:saddle_ranch_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Chatbot Modal Tests', () {
    testWidgets('Renders Help Assisstant modal structure correctly', (WidgetTester tester) async {
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
      expect(find.text('Help Assisstant'), findsAtLeast(1));
      expect(find.byType(Image), findsOneWidget);

      // Check quick chips
      expect(find.text('📍 Locations'), findsOneWidget);
      expect(find.text('🕒 Hours'), findsOneWidget);
      expect(find.text('🥩 Menu & Prices'), findsOneWidget);
      expect(find.text('🎉 Promos'), findsOneWidget);
      expect(find.text('🎟️ Vouchers'), findsOneWidget);

      // Check text input field
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}

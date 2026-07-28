import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saddle_ranch_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Shows login screen on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const SaddleRanchApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsAtLeast(1));
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}

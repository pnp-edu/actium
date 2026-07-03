import 'package:flutter_test/flutter_test.dart';
import 'package:actium/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const ActiumApp());
      expect(find.byType(ActiumApp), findsOneWidget);
    });
  });
}

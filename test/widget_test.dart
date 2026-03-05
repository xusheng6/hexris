import 'package:flutter_test/flutter_test.dart';
import 'package:hexris/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const HexrisApp(initialHighScore: 0));
    expect(find.text('0'), findsWidgets);
  });
}

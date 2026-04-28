import 'package:flutter_test/flutter_test.dart';
import 'package:judis_ai/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const JudisAIApp());
    expect(find.text('JudisAI'), findsWidgets);
  });
}

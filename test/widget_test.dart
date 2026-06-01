import 'package:flutter_test/flutter_test.dart';
import 'package:adtech/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ADTechApp());
    expect(find.text('ADTech'), findsWidgets);
  });
}

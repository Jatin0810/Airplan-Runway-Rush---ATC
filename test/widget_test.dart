import 'package:flutter_test/flutter_test.dart';
import 'package:indian_atc/main.dart';

void main() {
  testWidgets('Indian ATC App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianAtcApp());
    await tester.pumpAndSettle();

    // Verify main menu elements exist
    expect(find.text('INDIAN ATC'), findsOneWidget);
    expect(find.text('CLASSIC GAME'), findsOneWidget);
    expect(find.text('LEVEL GAME (1 - 100)'), findsOneWidget);
  });
}

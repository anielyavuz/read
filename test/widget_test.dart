import 'package:flutter_test/flutter_test.dart';

import 'package:bookpulse/main.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BookpulseApp());
    await tester.pumpAndSettle();

    expect(find.text('Bookpulse'), findsOneWidget);
  });
}

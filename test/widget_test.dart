import 'package:flutter_test/flutter_test.dart';

import 'package:recimo/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RecimoApp());
    expect(find.text('Recimo'), findsOneWidget);
  });
}

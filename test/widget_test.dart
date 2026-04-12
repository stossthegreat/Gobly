import 'package:flutter_test/flutter_test.dart';

import 'package:gobly/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GoblyApp(showOnboarding: false));
    expect(find.text('Gobly'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:lifepilot/main.dart';

void main() {
  testWidgets('LifePilot app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LifePilotApp());

    await tester.pumpAndSettle();

    expect(find.text('LifePilot AI'), findsOneWidget);
    expect(
      find.text('Here is what needs attention now.'),
      findsOneWidget,
    );
  });
}

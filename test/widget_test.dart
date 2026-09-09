import 'package:flutter_test/flutter_test.dart';

import 'package:void_terminal_macos/main.dart';

void main() {
  testWidgets('App constructs without error', (WidgetTester tester) async {
    await tester.pumpWidget(const VoidTerminalApp());
    expect(find.byType(VoidTerminalApp), findsOneWidget);
  });
}

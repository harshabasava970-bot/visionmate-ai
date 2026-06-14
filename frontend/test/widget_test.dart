// VisionMate AI - Basic smoke test

import 'package:flutter_test/flutter_test.dart';
import 'package:visionmate_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionMateApp());
    // Just verify the app starts without crashing
    expect(find.byType(VisionMateApp), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:expiry_tracker/main.dart';

void main() {
  testWidgets('Expiry Tracker loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpiryTrackerApp());

    expect(find.text('Expiry Tracker'), findsOneWidget);
  });
}

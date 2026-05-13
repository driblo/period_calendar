import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/app.dart';

void main() {
  testWidgets('placeholder home renders app title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PeriodCalendarApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Period Calendar'), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
  });
}

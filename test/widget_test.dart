import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/app.dart';
import 'package:period_calendar/data/db/app_database.dart';
import 'package:period_calendar/features/calendar/calendar_providers.dart';

void main() {
  testWidgets('calendar page renders prediction with empty cycle history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cyclesProvider.overrideWith((ref) => Stream.value(<Cycle>[])),
        ],
        child: const PeriodCalendarApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Insights'), findsWidgets);

    // Tear down to flush pending timers from table_calendar.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

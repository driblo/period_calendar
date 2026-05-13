import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/app.dart';

void main() {
  testWidgets('placeholder home renders title and legend', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PeriodCalendarApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Period Calendar'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Legend'), findsOneWidget);
    expect(find.text('Period'), findsOneWidget);
    expect(find.text('Log period'), findsOneWidget);
  });
}

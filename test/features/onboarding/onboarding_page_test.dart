import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_calendar/features/onboarding/onboarding_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first slide renders title and progresses through slides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingPage(onFinished: () {})),
    );
    await tester.pump();

    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Log easily'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Yours alone'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  test('onboarded flag round-trips', () async {
    expect(await isOnboarded(), isFalse);
    await setOnboarded();
    expect(await isOnboarded(), isTrue);
  });
}

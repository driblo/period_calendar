import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/core/theme/warm_palette.dart';
import 'package:period_calendar/core/theme/warm_theme.dart';

void main() {
  group('WarmTheme', () {
    test('light theme uses Material 3 with cream surface', () {
      final theme = WarmTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, WarmPalette.cream);
    });

    test('dark theme uses Material 3', () {
      final theme = WarmTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('light onSurface vs surface meets WCAG AA (>= 4.5:1)', () {
      final scheme = WarmTheme.light().colorScheme;
      expect(
        _contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark onSurface vs surface meets WCAG AA (>= 4.5:1)', () {
      final scheme = WarmTheme.dark().colorScheme;
      expect(
        _contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

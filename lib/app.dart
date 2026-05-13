import 'package:flutter/material.dart';

class PeriodCalendarApp extends StatelessWidget {
  const PeriodCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB55542)),
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa_outlined, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Period Calendar',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'M0 bootstrap complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

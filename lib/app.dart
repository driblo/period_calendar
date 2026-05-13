import 'package:flutter/material.dart';

import 'core/theme/warm_palette.dart';
import 'core/theme/warm_theme.dart';
import 'core/widgets/section_header.dart';
import 'core/widgets/warm_card.dart';

class PeriodCalendarApp extends StatelessWidget {
  const PeriodCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Calendar',
      debugShowCheckedModeBanner: false,
      theme: WarmTheme.light(),
      darkTheme: WarmTheme.dark(),
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
      appBar: AppBar(title: const Text('Period Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Icon(Icons.spa_outlined, size: 56, color: scheme.primary),
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Today'),
          WarmCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: WarmPalette.rose,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.water_drop, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cycle not started',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Log your first period to see predictions.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Legend'),
          WarmCard(
            child: Column(
              children: const [
                _LegendRow(color: WarmPalette.flow, label: 'Period'),
                SizedBox(height: 8),
                _LegendRow(color: WarmPalette.predicted, label: 'Predicted'),
                SizedBox(height: 8),
                _LegendRow(color: WarmPalette.fertile, label: 'Fertile window'),
                SizedBox(height: 8),
                _LegendRow(color: WarmPalette.ovulation, label: 'Ovulation'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Log period'),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

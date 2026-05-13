import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/warm_palette.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/warm_card.dart';
import '../calendar/calendar_providers.dart';
import 'cycle_stats.dart';

const _calc = CycleStatsCalculator();

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cycles) {
          final stats = _calc.compute(cycles);
          if (!stats.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Log at least 2 cycles to see insights.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'At a glance'),
              WarmCard(
                child: Row(
                  children: [
                    _statTile(
                      context,
                      label: 'Avg cycle',
                      value: stats.avgCycleLength!.toStringAsFixed(1),
                      unit: 'days',
                    ),
                    _statTile(
                      context,
                      label: 'Avg period',
                      value: stats.avgPeriodLength == null
                          ? '—'
                          : stats.avgPeriodLength!.toStringAsFixed(1),
                      unit: 'days',
                    ),
                    _statTile(
                      context,
                      label: 'Range',
                      value: '${stats.shortestCycle}–${stats.longestCycle}',
                      unit: 'days',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Last cycles'),
              WarmCard(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: SizedBox(
                  height: 200,
                  child: Semantics(
                    label: 'Bar chart of recent cycle lengths',
                    child: _CycleLengthsChart(lengths: stats.cycleLengths),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(unit, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _CycleLengthsChart extends StatelessWidget {
  const _CycleLengthsChart({required this.lengths});
  final List<int> lengths;

  @override
  Widget build(BuildContext context) {
    final shown =
        lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
    final maxY =
        (shown.isEmpty ? 35 : shown.reduce((a, b) => a > b ? a : b) + 5)
            .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                'C${v.toInt() + 1}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              reservedSize: 24,
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < shown.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: shown[i].toDouble(),
                  color: WarmPalette.rose,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

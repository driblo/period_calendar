import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/warm_palette.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/warm_card.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import 'calendar_providers.dart';
import 'day_classifier.dart';
import 'day_detail_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final prediction = ref.watch(cyclePredictionProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cycles) {
          final classifier = DayClassifier(
            cycles: cycles,
            prediction: prediction,
            loggedDates: const {},
          );

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              WarmCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: TableCalendar<DayKind>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) =>
                      _selected != null && isSameDay(d, _selected),
                  startingDayOfWeek: _firstDayOfWeekFor(context),
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle:
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                  onDaySelected: (day, focused) {
                    setState(() {
                      _selected = day;
                      _focused = focused;
                    });
                    _openDaySheet(day);
                  },
                  onPageChanged: (d) => setState(() => _focused = d),
                  calendarBuilders: CalendarBuilders<DayKind>(
                    defaultBuilder: (ctx, day, _) =>
                        _DayCell(day: day, kind: classifier.classify(day)),
                    todayBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      kind: classifier.classify(day),
                      isToday: true,
                    ),
                    selectedBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      kind: classifier.classify(day),
                      isSelected: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Prediction'),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _predictionRow(
                      context,
                      icon: Icons.water_drop,
                      color: WarmPalette.predicted,
                      label: 'Next period',
                      value:
                          '${DateFormat.MMMd().format(prediction.nextPeriodStart)} – ${DateFormat.MMMd().format(prediction.nextPeriodEnd)}',
                    ),
                    const SizedBox(height: 8),
                    _predictionRow(
                      context,
                      icon: Icons.brightness_5,
                      color: WarmPalette.fertile,
                      label: 'Fertile window',
                      value:
                          '${DateFormat.MMMd().format(prediction.fertileWindowStart)} – ${DateFormat.MMMd().format(prediction.fertileWindowEnd)}',
                    ),
                    const SizedBox(height: 8),
                    _predictionRow(
                      context,
                      icon: Icons.brightness_2,
                      color: WarmPalette.ovulation,
                      label: 'Ovulation',
                      value: DateFormat.MMMd().format(prediction.ovulationDate),
                    ),
                    if (prediction.irregular) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: scheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your cycles are quite variable; predictions '
                                'may be less accurate.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onTertiaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (cycles.isEmpty) _onboardingHint(context),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        icon: const Icon(Icons.add),
        label: Text(_fabLabel(cyclesAsync.valueOrNull ?? const [])),
      ),
    );
  }

  String _fabLabel(List<Cycle> cycles) {
    if (cycles.isEmpty || cycles.last.endDate != null) {
      return 'Period started today';
    }
    return 'Period ended today';
  }

  Future<void> _onFabPressed() async {
    final repo = ref.read(cycleRepositoryProvider);
    final cycles = ref.read(cyclesProvider).valueOrNull ?? const <Cycle>[];
    final today = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);

    if (cycles.isEmpty || cycles.last.endDate != null) {
      await repo.startCycle(today);
      messenger.showSnackBar(
        const SnackBar(content: Text('Period start logged')),
      );
    } else {
      await repo.endCurrentCycle(today);
      messenger.showSnackBar(
        const SnackBar(content: Text('Period end logged')),
      );
    }
  }

  Future<void> _openDaySheet(DateTime day) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DayDetailSheet(day: day),
    );
  }

  StartingDayOfWeek _firstDayOfWeekFor(BuildContext context) {
    // Use the locale's first day where possible; fall back to Monday.
    final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en_US';
    final us = locale.startsWith('en_US') || locale.startsWith('en_CA');
    return us ? StartingDayOfWeek.sunday : StartingDayOfWeek.monday;
  }

  Widget _predictionRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _onboardingHint(BuildContext context) {
    return WarmCard(
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap "Period started today" to log your first cycle. '
              'Predictions improve as you log more.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.kind,
    this.isToday = false,
    this.isSelected = false,
  });

  final DateTime day;
  final DayKind kind;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = _colorsFor(kind, scheme);
    final border = isSelected
        ? Border.all(color: scheme.primary, width: 2)
        : isToday
            ? Border.all(color: scheme.outline, width: 1)
            : null;

    return Center(
      child: Semantics(
        label: '${day.day} ${_semanticsLabelFor(kind)}',
        button: true,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            border: border,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: kind == DayKind.none ? null : FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg) _colorsFor(DayKind kind, ColorScheme scheme) {
    switch (kind) {
      case DayKind.period:
        return (WarmPalette.flow, Colors.white);
      case DayKind.predictedPeriod:
        return (WarmPalette.predicted.withValues(alpha: 0.6), Colors.white);
      case DayKind.fertile:
        return (WarmPalette.fertile.withValues(alpha: 0.55), Colors.white);
      case DayKind.ovulation:
        return (WarmPalette.ovulation, Colors.white);
      case DayKind.logged:
        return (scheme.surfaceContainerHighest, scheme.onSurface);
      case DayKind.none:
        return (Colors.transparent, scheme.onSurface);
    }
  }

  String _semanticsLabelFor(DayKind kind) {
    switch (kind) {
      case DayKind.period:
        return 'period day';
      case DayKind.predictedPeriod:
        return 'predicted period';
      case DayKind.fertile:
        return 'fertile day';
      case DayKind.ovulation:
        return 'ovulation day';
      case DayKind.logged:
        return 'logged entry';
      case DayKind.none:
        return '';
    }
  }
}

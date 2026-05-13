import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';

const _allSymptoms = <String>[
  'cramps',
  'headache',
  'backache',
  'bloating',
  'acne',
  'nausea',
  'fatigue',
  'tender_breasts',
];

class DayDetailSheet extends ConsumerStatefulWidget {
  const DayDetailSheet({super.key, required this.day});
  final DateTime day;

  @override
  ConsumerState<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<DayDetailSheet> {
  int? _flow;
  int? _mood;
  int? _energy;
  final Set<String> _symptoms = <String>{};
  String _notes = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(dailyLogRepositoryProvider);
    final log = await repo.forDate(widget.day);
    if (log != null) {
      _flow = log.flow;
      _mood = log.mood;
      _energy = log.energy;
      _notes = log.notes ?? '';
      final s = await repo.symptomsFor(log.id);
      _symptoms.addAll(s.map((e) => e.type));
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final repo = ref.read(dailyLogRepositoryProvider);
    await repo.saveLog(
      date: widget.day,
      mood: _mood,
      energy: _energy,
      flow: _flow,
      notes: _notes.isEmpty ? null : _notes,
    );
    final log = await repo.forDate(widget.day);
    if (log != null) {
      await repo.setSymptoms(log.id, _symptoms.toList());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: !_loaded
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      DateFormat.yMMMMEEEEd().format(widget.day),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Flow', style: theme.textTheme.labelLarge),
                    _segmented(
                      values: const [0, 1, 2, 3, 4],
                      labels: const ['None', 'Spot', 'Light', 'Med', 'Heavy'],
                      selected: _flow,
                      onChanged: (v) => setState(() => _flow = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Mood (1–5)', style: theme.textTheme.labelLarge),
                    _segmented(
                      values: const [1, 2, 3, 4, 5],
                      labels: const ['😞', '😕', '😐', '🙂', '😄'],
                      selected: _mood,
                      onChanged: (v) => setState(() => _mood = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Energy (1–5)', style: theme.textTheme.labelLarge),
                    _segmented(
                      values: const [1, 2, 3, 4, 5],
                      labels: const ['1', '2', '3', '4', '5'],
                      selected: _energy,
                      onChanged: (v) => setState(() => _energy = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Symptoms', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _allSymptoms)
                          FilterChip(
                            label: Text(s.replaceAll('_', ' ')),
                            selected: _symptoms.contains(s),
                            onSelected: (v) => setState(() {
                              if (v) {
                                _symptoms.add(s);
                              } else {
                                _symptoms.remove(s);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Notes', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _notes,
                      minLines: 2,
                      maxLines: 5,
                      onChanged: (v) => _notes = v,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Anything you want to remember…',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _save,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _segmented({
    required List<int> values,
    required List<String> labels,
    required int? selected,
    required ValueChanged<int?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SegmentedButton<int>(
        segments: [
          for (var i = 0; i < values.length; i++)
            ButtonSegment(value: values[i], label: Text(labels[i])),
        ],
        selected: selected == null ? <int>{} : {selected},
        emptySelectionAllowed: true,
        multiSelectionEnabled: false,
        onSelectionChanged: (s) => onChanged(s.isEmpty ? null : s.first),
      ),
    );
  }
}

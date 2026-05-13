enum ReminderType {
  periodSoon,
  logToday,
  pill;

  static ReminderType fromName(String name) =>
      ReminderType.values.firstWhere((r) => r.name == name);
}

class ReminderSpec {
  const ReminderSpec({
    required this.type,
    required this.hour,
    required this.minute,
    this.daysBefore = 0,
    this.enabled = true,
  });

  final ReminderType type;
  final int hour;
  final int minute;
  final int daysBefore;
  final bool enabled;
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  annually;

  /// Human-readable label. Wire this to context.tr!.xxx later if you want
  /// it localized — for now it's a plain fallback so nothing breaks.
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.annually:
        return 'Annually';
    }
  }

  /// Computes the next occurrence strictly after [from].
  DateTime next(DateTime from) {
    switch (this) {
      case RecurrenceFrequency.daily:
        return DateTime(from.year, from.month, from.day + 1, from.hour, from.minute);
      case RecurrenceFrequency.weekly:
        return DateTime(from.year, from.month, from.day + 7, from.hour, from.minute);
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      case RecurrenceFrequency.annually:
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
    }
  }
}

/// Day keys are `yyyy-MM-dd` in the device's local calendar day.
String dayKey([DateTime? date]) {
  final d = (date ?? DateTime.now()).toLocal();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

DateTime? dateFromDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Accepts ISO-8601 strings (this app) and Foundation's default `Date`
/// encoding — seconds since 2001-01-01 UTC (the Swift app).
DateTime? parseFlexibleDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is num) {
    final reference = DateTime.utc(2001, 1, 1);
    return reference.add(Duration(milliseconds: (value * 1000).round())).toLocal();
  }
  return null;
}

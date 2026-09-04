import '../util/dates.dart';
import 'wird.dart';

/// One day's completion record.
///
/// `completed` — wird id → count reached (never decreases within the day).
/// `readAt`    — wird id → the moment the wird was completed ("read") that day.
/// `lit`       — whether the day was fully lit, recorded when it happened, so
///               history never changes when the awrād change later.
class DayRecord {
  final Map<String, int> completed;
  final Map<String, DateTime> readAt;
  bool? lit;

  DayRecord({Map<String, int>? completed, Map<String, DateTime>? readAt, this.lit})
      : completed = completed ?? {},
        readAt = readAt ?? {};

  bool isDone(Wird wird) => (completed[wird.id] ?? 0) >= wird.targetCount;

  int count(Wird wird) => completed[wird.id] ?? 0;

  DayRecord copy() => DayRecord(
        completed: Map.of(completed),
        readAt: Map.of(readAt),
        lit: lit,
      );

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'readAt': {
          for (final e in readAt.entries) e.key: e.value.toIso8601String(),
        },
        if (lit != null) 'lit': lit,
      };

  /// Tolerant decoder: the Swift app encodes `[UUID: Int]` / `[UUID: Date]`
  /// as flat `[key, value, key, value…]` arrays (dates as seconds since 2001) —
  /// both shapes are accepted, so an existing iPhone install keeps its light.
  factory DayRecord.fromJson(Map<String, dynamic> json) {
    final completed = <String, int>{};
    _forEachPair(json['completed'], (k, v) {
      if (v is num) completed[k] = v.toInt();
    });
    final readAt = <String, DateTime>{};
    _forEachPair(json['readAt'], (k, v) {
      final parsed = parseFlexibleDate(v);
      if (parsed != null) readAt[k] = parsed;
    });
    return DayRecord(completed: completed, readAt: readAt, lit: json['lit'] as bool?);
  }

  static void _forEachPair(Object? raw, void Function(String key, Object? value) visit) {
    if (raw is Map) {
      raw.forEach((k, v) => visit(k.toString().toUpperCase(), v));
    } else if (raw is List) {
      for (var i = 0; i + 1 < raw.length; i += 2) {
        final k = raw[i];
        if (k is String) visit(k.toUpperCase(), raw[i + 1]);
      }
    }
  }
}

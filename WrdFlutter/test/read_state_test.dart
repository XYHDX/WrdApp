import 'package:flutter_test/flutter_test.dart';
import 'package:wrd/models/day_record.dart';
import 'package:wrd/models/gate.dart';
import 'package:wrd/models/wird.dart';
import 'package:wrd/util/dates.dart';

void main() {
  final tasbih = Wird(id: 'A', title: 'تسبيح', gate: Gate.afterPrayer, targetCount: 33);
  final ayah = Wird(id: 'B', title: 'آية الكرسي', gate: Gate.morning);

  group('read / not read per day', () {
    test('a wird is read only when its count reaches the target', () {
      final day = DayRecord();
      expect(day.isDone(tasbih), isFalse);
      day.completed['A'] = 32;
      expect(day.isDone(tasbih), isFalse);
      day.completed['A'] = 33;
      expect(day.isDone(tasbih), isTrue);
    });

    test('the state resets with the day: yesterday read, today not read', () {
      final days = <String, DayRecord>{};
      final yesterday = dayKey(DateTime(2026, 9, 2));
      final today = dayKey(DateTime(2026, 9, 3));

      days[yesterday] = DayRecord(completed: {'B': 1}, readAt: {'B': DateTime(2026, 9, 2, 6, 40)});
      expect(days[yesterday]!.isDone(ayah), isTrue);

      final todayRecord = days[today] ?? DayRecord();
      expect(todayRecord.isDone(ayah), isFalse, reason: 'new day starts unread');
      expect(todayRecord.readAt['B'], isNull);

      // Yesterday's light is untouched by today's state.
      expect(days[yesterday]!.isDone(ayah), isTrue);
    });

    test('day keys are local calendar days', () {
      expect(dayKey(DateTime(2026, 9, 3, 23, 59)), '2026-09-03');
      expect(dayKey(DateTime(2026, 9, 4, 0, 0, 1)), '2026-09-04');
      expect(dateFromDayKey('2026-09-03'), DateTime(2026, 9, 3));
    });
  });

  group('compatibility with the Swift app state file', () {
    test('accepts the flat [key, value, …] dictionary encoding', () {
      final record = DayRecord.fromJson({
        'completed': ['d0000000-0000-4000-8000-000000000006', 100, 'D0000000-0000-4000-8000-000000000001', 1],
      });
      expect(record.completed['D0000000-0000-4000-8000-000000000006'], 100);
      expect(record.completed['D0000000-0000-4000-8000-000000000001'], 1);
      expect(record.readAt, isEmpty);
    });

    test('accepts Swift readAt-style flat arrays with reference-date seconds', () {
      final record = DayRecord.fromJson({
        'completed': ['A', 33],
        'readAt': ['A', 810086400], // 2026-09-03T00:00:00Z
      });
      expect(record.readAt['A']!.toUtc(), DateTime.utc(2026, 9, 3));
    });

    test('the lit flag round-trips and is absent by default', () {
      expect(DayRecord().toJson().containsKey('lit'), isFalse);
      final lit = DayRecord(completed: {'B': 1}, lit: true);
      expect(DayRecord.fromJson(lit.toJson()).lit, isTrue);
    });

    test('accepts the map encoding this app writes, with readAt', () {
      final original = DayRecord(completed: {'A': 33}, readAt: {'A': DateTime(2026, 9, 3, 13, 5)});
      final decoded = DayRecord.fromJson(original.toJson());
      expect(decoded.completed, {'A': 33});
      expect(decoded.readAt['A'], DateTime(2026, 9, 3, 13, 5));
    });

    test('Foundation reference-date seconds decode to the right instant', () {
      // 2026-09-03T00:00:00Z is 810,086,400 s after 2001-01-01T00:00:00Z.
      final d = parseFlexibleDate(810086400)!.toUtc();
      expect(d, DateTime.utc(2026, 9, 3));
    });
  });
}

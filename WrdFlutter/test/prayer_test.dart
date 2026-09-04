import 'package:flutter_test/flutter_test.dart';
import 'package:wrd/prayer/prayer_calculator.dart';
import 'package:wrd/prayer/prayer_method.dart';

void main() {
  group('country → method', () {
    test('Gulf, Egypt, South Asia, Turkey, North America, Indonesia', () {
      expect(PrayerMethod.forCountry('SA'), PrayerMethod.ummAlQura);
      expect(PrayerMethod.forCountry('ae'), PrayerMethod.dubai);
      expect(PrayerMethod.forCountry('EG'), PrayerMethod.egyptian);
      expect(PrayerMethod.forCountry('PK'), PrayerMethod.karachi);
      expect(PrayerMethod.forCountry('TR'), PrayerMethod.turkey);
      expect(PrayerMethod.forCountry('US'), PrayerMethod.northAmerica);
      expect(PrayerMethod.forCountry('ID'), PrayerMethod.kemenag);
      expect(PrayerMethod.forCountry('MY'), PrayerMethod.jakim);
    });

    test('Syria and unknown countries fall back to Muslim World League', () {
      expect(PrayerMethod.forCountry('SY'), PrayerMethod.muslimWorldLeague);
      expect(PrayerMethod.forCountry(null), PrayerMethod.muslimWorldLeague);
      expect(PrayerMethod.forCountry('ZZ'), PrayerMethod.muslimWorldLeague);
    });

    test('Ḥanafī Asr where it is the convention', () {
      expect(PrayerMethod.madhabForCountry('PK'), Madhab.hanafi);
      expect(PrayerMethod.madhabForCountry('SA'), Madhab.shafi);
    });
  });

  group('calculator', () {
    int minutesBetween(DateTime a, DateTime b) => b.difference(a).inMinutes;

    test('Damascus, 3 Sep 2026, MWL — intervals match the reference library', () {
      // Reference (adhanpy, MWL): fajr 04:44 · sunrise 06:10 · dhuhr 12:35
      // asr 16:10 · maghrib 18:58 · isha 20:18 (Asia/Damascus). Intervals are
      // time-zone independent, so the test holds on any machine.
      final t = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 33.5138,
        longitude: 36.2765,
        settings: const PrayerSettings(method: PrayerMethod.muslimWorldLeague),
      );
      final fajr = t.time(PrayerName.fajr)!;
      final sunrise = t.time(PrayerName.sunrise)!;
      final dhuhr = t.time(PrayerName.dhuhr)!;
      final asr = t.time(PrayerName.asr)!;
      final maghrib = t.time(PrayerName.maghrib)!;
      final isha = t.time(PrayerName.isha)!;

      expect(minutesBetween(fajr, sunrise), inInclusiveRange(85, 87));
      expect(minutesBetween(sunrise, dhuhr), inInclusiveRange(384, 386));
      expect(minutesBetween(dhuhr, asr), inInclusiveRange(214, 216));
      expect(minutesBetween(asr, maghrib), inInclusiveRange(167, 169));
      expect(minutesBetween(maghrib, isha), inInclusiveRange(79, 81));
    });

    test('Umm al-Qura: Isha is Maghrib + 90 min (120 in Ramadan)', () {
      final normal = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 21.4225,
        longitude: 39.8262,
        settings: const PrayerSettings(method: PrayerMethod.ummAlQura),
      );
      expect(
        minutesBetween(normal.time(PrayerName.maghrib)!, normal.time(PrayerName.isha)!),
        90,
      );
      final ramadan = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 21.4225,
        longitude: 39.8262,
        settings: const PrayerSettings(method: PrayerMethod.ummAlQura, isRamadan: true),
      );
      expect(
        minutesBetween(ramadan.time(PrayerName.maghrib)!, ramadan.time(PrayerName.isha)!),
        120,
      );
    });

    test('Ḥanafī Asr is later than Shafiʿī Asr', () {
      final shafi = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 24.8607,
        longitude: 67.0011,
        settings: const PrayerSettings(method: PrayerMethod.karachi),
      );
      final hanafi = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 24.8607,
        longitude: 67.0011,
        settings: const PrayerSettings(method: PrayerMethod.karachi, madhab: Madhab.hanafi),
      );
      expect(hanafi.time(PrayerName.asr)!.isAfter(shafi.time(PrayerName.asr)!), isTrue);
    });

    test('High latitude midsummer does not crash and still yields all six times', () {
      final t = PrayerCalculator.times(
        date: DateTime(2027, 6, 21),
        latitude: 59.3293, // Stockholm
        longitude: 18.0686,
        settings: const PrayerSettings(method: PrayerMethod.muslimWorldLeague),
      );
      for (final p in PrayerName.values) {
        expect(t.time(p), isNotNull, reason: '$p missing');
      }
      expect(t.time(PrayerName.fajr)!.isBefore(t.time(PrayerName.sunrise)!), isTrue);
      expect(t.time(PrayerName.isha)!.isAfter(t.time(PrayerName.maghrib)!), isTrue);
    });

    test('user minute adjustments shift a single prayer', () {
      final base = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 33.5138,
        longitude: 36.2765,
      );
      final shifted = PrayerCalculator.times(
        date: DateTime(2026, 9, 3),
        latitude: 33.5138,
        longitude: 36.2765,
        settings: const PrayerSettings(userAdjustments: PrayerAdjustments(fajr: 3)),
      );
      expect(minutesBetween(base.time(PrayerName.fajr)!, shifted.time(PrayerName.fajr)!), 3);
      expect(base.time(PrayerName.dhuhr), shifted.time(PrayerName.dhuhr));
    });
  });
}

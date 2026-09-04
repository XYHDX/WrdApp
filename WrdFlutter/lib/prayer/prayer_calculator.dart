import 'dart:math' as math;

import 'prayer_method.dart';

/// On-device prayer times — standard solar astronomy, fully offline.
///
/// The algorithm is the widely used PrayTimes formulation (two-pass
/// refinement of the sun's declination and equation of time at each prayer),
/// parameterised by [PrayerMethod], [Madhab] and [HighLatitudeRule].
/// Accuracy is within about a minute of the reference libraries; the
/// authority conventions (angles, intervals, minute offsets) are what make
/// the result match the official tables people see in each country.
enum PrayerName {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.sunrise:
        return 'الشروق';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  static const List<PrayerName> prayersOnly = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];
}

class DayPrayers {
  final Map<PrayerName, DateTime> times;
  const DayPrayers(this.times);

  DateTime? time(PrayerName prayer) => times[prayer];

  /// The next prayer (excluding sunrise) after the given moment, if any remain.
  (PrayerName, DateTime)? nextPrayer([DateTime? after]) {
    final now = after ?? DateTime.now();
    for (final prayer in PrayerName.prayersOnly) {
      final t = times[prayer];
      if (t != null && t.isAfter(now)) return (prayer, t);
    }
    return null;
  }

  /// The prayer whose time we are currently in (excluding sunrise).
  PrayerName? currentPrayer([DateTime? at]) {
    final now = at ?? DateTime.now();
    PrayerName? current;
    for (final prayer in PrayerName.prayersOnly) {
      final t = times[prayer];
      if (t != null && !t.isAfter(now)) current = prayer;
    }
    return current;
  }
}

class PrayerSettings {
  final PrayerMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final PrayerAdjustments userAdjustments;
  final bool isRamadan;

  const PrayerSettings({
    this.method = PrayerMethod.muslimWorldLeague,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
    this.userAdjustments = PrayerAdjustments.none,
    this.isRamadan = false,
  });
}

class PrayerCalculator {
  PrayerCalculator._();

  /// Prayer times for the local calendar day containing [date], at a
  /// coordinate, using the device time zone offset in force at noon that day.
  static DayPrayers times({
    required DateTime date,
    required double latitude,
    required double longitude,
    PrayerSettings settings = const PrayerSettings(),
    double elevationMeters = 0,
  }) {
    final local = date.toLocal();
    final year = local.year, month = local.month, day = local.day;
    final noon = DateTime(year, month, day, 12);
    final tzHours = noon.timeZoneOffset.inMinutes / 60.0;

    // Julian date at local solar midnight for this longitude.
    final jDate = _julian(year, month, day) - longitude / (15 * 24);

    // Two-pass computation (initial guesses → refined).
    var portions = <String, double>{
      'fajr': 5 / 24,
      'sunrise': 6 / 24,
      'dhuhr': 12 / 24,
      'asr': 13 / 24,
      'sunset': 18 / 24,
      'maghrib': 18 / 24,
      'isha': 18 / 24,
    };
    Map<String, double> t = {};
    for (var pass = 0; pass < 2; pass++) {
      t = _compute(portions, jDate, latitude, settings, elevationMeters);
      // A time the sun never reaches (high latitudes in summer) is NaN —
      // keep the previous guess for the refinement pass instead of
      // propagating NaN into the trigonometry.
      portions = {
        for (final e in t.entries)
          e.key: e.value.isNaN ? portions[e.key]! : e.value / 24,
      };
    }

    // Local solar hours → clock hours.
    final offset = tzHours - longitude / 15;
    final adjusted = {for (final e in t.entries) e.key: e.value + offset};

    _adjustHighLatitudes(adjusted, settings);

    if (settings.method.ishaByInterval) {
      final interval = settings.isRamadan && settings.method.ramadanIshaIntervalMinutes > 0
          ? settings.method.ramadanIshaIntervalMinutes
          : settings.method.ishaIntervalMinutes;
      adjusted['isha'] = adjusted['maghrib']! + interval / 60;
    }

    final adj = settings.method.adjustments + settings.userAdjustments;
    adjusted['fajr'] = adjusted['fajr']! + adj.fajr / 60;
    adjusted['sunrise'] = adjusted['sunrise']! + adj.sunrise / 60;
    adjusted['dhuhr'] = adjusted['dhuhr']! + adj.dhuhr / 60;
    adjusted['asr'] = adjusted['asr']! + adj.asr / 60;
    adjusted['maghrib'] = adjusted['maghrib']! + adj.maghrib / 60;
    adjusted['isha'] = adjusted['isha']! + adj.isha / 60;

    final midnight = DateTime(year, month, day);
    DateTime? toDate(double? hours) {
      if (hours == null || hours.isNaN) return null;
      final rounded = (hours * 60).round(); // whole minutes, like the tables
      return midnight.add(Duration(minutes: rounded));
    }

    final result = <PrayerName, DateTime>{};
    void put(PrayerName p, String key) {
      final d = toDate(adjusted[key]);
      if (d != null) result[p] = d;
    }

    put(PrayerName.fajr, 'fajr');
    put(PrayerName.sunrise, 'sunrise');
    put(PrayerName.dhuhr, 'dhuhr');
    put(PrayerName.asr, 'asr');
    put(PrayerName.maghrib, 'maghrib');
    put(PrayerName.isha, 'isha');
    return DayPrayers(result);
  }

  // ---------------------------------------------------------------------------

  static Map<String, double> _compute(
    Map<String, double> portions,
    double jDate,
    double lat,
    PrayerSettings s,
    double elevation,
  ) {
    final method = s.method;
    final horizon = 0.833 + 0.0347 * math.sqrt(math.max(elevation, 0));
    final asrFactor = s.madhab == Madhab.hanafi ? 2.0 : 1.0;

    final fajr = _sunAngleTime(method.fajrAngle, portions['fajr']!, jDate, lat, ccw: true);
    final sunrise = _sunAngleTime(horizon, portions['sunrise']!, jDate, lat, ccw: true);
    final dhuhr = _midDay(portions['dhuhr']!, jDate);
    final asr = _asrTime(asrFactor, portions['asr']!, jDate, lat);
    final sunset = _sunAngleTime(horizon, portions['sunset']!, jDate, lat);
    final maghrib = method.maghribAngle > 0
        ? _sunAngleTime(method.maghribAngle, portions['maghrib']!, jDate, lat)
        : sunset;
    final isha = method.ishaByInterval
        ? maghrib // filled in later as maghrib + interval
        : _sunAngleTime(method.ishaAngle, portions['isha']!, jDate, lat);

    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'sunset': sunset,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  static void _adjustHighLatitudes(Map<String, double> t, PrayerSettings s) {
    final sunrise = t['sunrise']!, sunset = t['sunset']!;
    if (sunrise.isNaN || sunset.isNaN) return; // polar day/night — leave as is
    final night = _fixHour(sunrise - sunset); // length of the night in hours

    double portion(double angle) {
      switch (s.highLatitudeRule) {
        case HighLatitudeRule.twilightAngle:
          return angle / 60 * night;
        case HighLatitudeRule.seventhOfTheNight:
          return night / 7;
        case HighLatitudeRule.middleOfTheNight:
          return night / 2;
      }
    }

    final fajrPortion = portion(s.method.fajrAngle);
    final fajr = t['fajr']!;
    if (fajr.isNaN || _fixHour(sunrise - fajr) > fajrPortion) {
      t['fajr'] = sunrise - fajrPortion;
    }

    if (!s.method.ishaByInterval) {
      final ishaPortion = portion(s.method.ishaAngle);
      final isha = t['isha']!;
      if (isha.isNaN || _fixHour(isha - sunset) > ishaPortion) {
        t['isha'] = sunset + ishaPortion;
      }
    }

    if (s.method.maghribAngle > 0) {
      final maghribPortion = portion(s.method.maghribAngle);
      final maghrib = t['maghrib']!;
      if (maghrib.isNaN || _fixHour(maghrib - sunset) > maghribPortion) {
        t['maghrib'] = sunset + maghribPortion;
      }
    }
  }

  // Solar position -------------------------------------------------------------

  /// (declination °, equation of time h) at [jd].
  static (double, double) _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = _fixHour(_atan2(_cos(e) * _sin(l), _cos(l)) / 15);
    final declination = _asin(_sin(e) * _sin(l));
    final eqt = q / 15 - ra;
    return (declination, eqt);
  }

  static double _midDay(double time, double jDate) {
    final (_, eqt) = _sunPosition(jDate + time);
    return _fixHour(12 - eqt);
  }

  /// Time (h) when the sun reaches [angle] below the horizon, after noon
  /// (clockwise) or before it (counter-clockwise). NaN when it never does.
  static double _sunAngleTime(double angle, double time, double jDate, double lat,
      {bool ccw = false}) {
    final (decl, _) = _sunPosition(jDate + time);
    final noon = _midDay(time, jDate);
    final cosH = (-_sin(angle) - _sin(decl) * _sin(lat)) / (_cos(decl) * _cos(lat));
    if (cosH < -1 || cosH > 1) return double.nan;
    final t = _acos(cosH) / 15;
    return noon + (ccw ? -t : t);
  }

  static double _asrTime(double factor, double time, double jDate, double lat) {
    final (decl, _) = _sunPosition(jDate + time);
    final angle = -_acot(factor + _tan((lat - decl).abs()));
    return _sunAngleTime(angle, time, jDate, lat);
  }

  // Helpers -------------------------------------------------------------------

  static double _julian(int year, int month, int day) {
    var y = year, m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5;
  }

  static double _fixAngle(double a) => _fix(a, 360);
  static double _fixHour(double a) => _fix(a, 24);
  static double _fix(double a, double b) {
    if (a.isNaN || a.isInfinite) return double.nan;
    final r = a - b * (a / b).floor();
    return r < 0 ? r + b : r;
  }

  static double _dtr(double d) => d * math.pi / 180;
  static double _rtd(double r) => r * 180 / math.pi;
  static double _sin(double d) => math.sin(_dtr(d));
  static double _cos(double d) => math.cos(_dtr(d));
  static double _tan(double d) => math.tan(_dtr(d));
  static double _asin(double x) => _rtd(math.asin(x));
  static double _acos(double x) => _rtd(math.acos(x));
  static double _atan2(double y, double x) => _rtd(math.atan2(y, x));
  static double _acot(double x) => _rtd(math.atan(1 / x));
}

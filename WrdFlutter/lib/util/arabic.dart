import 'package:hijri/hijri_calendar.dart';

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Arabic-Indic digits for counts and stats — "٣٣".
String arabicNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString().split('').map((c) {
    final n = int.tryParse(c);
    return n == null ? c : _arabicDigits[n];
  }).join();
  return negative ? '−$digits' : digits;
}

/// A clock time in Arabic digits, 12-hour, e.g. "٥:١٢".
String timeString(DateTime date) {
  final local = date.toLocal();
  var hour = local.hour % 12;
  if (hour == 0) hour = 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${arabicNumber(hour)}:${_digits(minute)}';
}

/// Minutes-from-midnight as an Arabic clock time, e.g. "٦:٣٠".
String minutesTimeString(int minutes) {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day).add(Duration(minutes: minutes));
  return timeString(date);
}

String _digits(String s) =>
    s.split('').map((c) => int.tryParse(c) == null ? c : _arabicDigits[int.parse(c)]).join();

// ---------------------------------------------------------------------------
// Hijri — Umm al-Qura, in Arabic.

const hijriMonthNames = [
  'محرّم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوّال',
  'ذو القعدة',
  'ذو الحجة',
];

const _weekdayNames = {
  DateTime.saturday: 'السبت',
  DateTime.sunday: 'الأحد',
  DateTime.monday: 'الاثنين',
  DateTime.tuesday: 'الثلاثاء',
  DateTime.wednesday: 'الأربعاء',
  DateTime.thursday: 'الخميس',
  DateTime.friday: 'الجمعة',
};

class HijriDate {
  /// "الخميس، ٢٠ ربيع الأول ١٤٤٨"
  static String format(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final weekday = _weekdayNames[date.weekday] ?? '';
    return '$weekday، ${arabicNumber(h.hDay)} ${hijriMonthNames[h.hMonth - 1]} ${arabicNumber(h.hYear)}';
  }

  static String today() => format(DateTime.now());

  /// "ربيع الأول ١٤٤٨"
  static String currentMonth() {
    final h = HijriCalendar.now();
    return '${hijriMonthNames[h.hMonth - 1]} ${arabicNumber(h.hYear)}';
  }

  /// True during Ramadan — Umm al-Qura lengthens the Isha interval then.
  static bool isRamadan([DateTime? date]) =>
      HijriCalendar.fromDate(date ?? DateTime.now()).hMonth == 9;

  /// The gregorian dates of the current hijri month, in order.
  static List<DateTime> currentMonthDays() {
    final h = HijriCalendar.now();
    final length = h.lengthOfMonth;
    final converter = HijriCalendar();
    return List.generate(length, (i) {
      final g = converter.hijriToGregorian(h.hYear, h.hMonth, i + 1);
      return DateTime(g.year, g.month, g.day);
    });
  }

  static int currentHijriDay() => HijriCalendar.now().hDay;
}

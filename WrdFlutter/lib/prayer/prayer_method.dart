/// Calculation conventions used around the Muslim world.
///
/// Angles and minute adjustments follow the published conventions of each
/// authority (as catalogued by the Adhan library and the AlAdhan API).
/// The default for a country is chosen in [PrayerMethod.forCountry]; the
/// user can always override it in Settings.
enum Madhab {
  shafi, // shadow = object length (Shafiʿī, Mālikī, Ḥanbalī)
  hanafi; // shadow = twice the object length

  String get arabicTitle =>
      this == Madhab.hanafi ? 'الحنفي (ظلّان)' : 'الجمهور — الشافعي (ظلّ واحد)';

  static Madhab fromWire(String? v) => v == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
}

enum HighLatitudeRule {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle;

  String get arabicTitle {
    switch (this) {
      case HighLatitudeRule.middleOfTheNight:
        return 'نصف الليل';
      case HighLatitudeRule.seventhOfTheNight:
        return 'سُبع الليل';
      case HighLatitudeRule.twilightAngle:
        return 'نسبة الزاوية';
    }
  }

  static HighLatitudeRule fromWire(String? v) {
    for (final r in HighLatitudeRule.values) {
      if (r.name == v) return r;
    }
    return HighLatitudeRule.middleOfTheNight;
  }
}

/// Per-prayer minute adjustments (positive = later).
class PrayerAdjustments {
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const PrayerAdjustments({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  static const none = PrayerAdjustments();

  PrayerAdjustments operator +(PrayerAdjustments other) => PrayerAdjustments(
        fajr: fajr + other.fajr,
        sunrise: sunrise + other.sunrise,
        dhuhr: dhuhr + other.dhuhr,
        asr: asr + other.asr,
        maghrib: maghrib + other.maghrib,
        isha: isha + other.isha,
      );

  Map<String, int> toJson() => {
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory PrayerAdjustments.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    int v(String k) => (json[k] as num?)?.toInt() ?? 0;
    return PrayerAdjustments(
      fajr: v('fajr'),
      sunrise: v('sunrise'),
      dhuhr: v('dhuhr'),
      asr: v('asr'),
      maghrib: v('maghrib'),
      isha: v('isha'),
    );
  }
}

enum PrayerMethod {
  muslimWorldLeague(
    arabicTitle: 'رابطة العالم الإسلامي',
    region: 'أوروبا · الشام · عامّة العالم',
    fajrAngle: 18,
    ishaAngle: 17,
    adjustments: PrayerAdjustments(dhuhr: 1),
  ),
  ummAlQura(
    arabicTitle: 'أم القرى — السعودية',
    region: 'السعودية · اليمن · البحرين · عُمان',
    fajrAngle: 18.5,
    ishaIntervalMinutes: 90,
    ramadanIshaIntervalMinutes: 120,
  ),
  egyptian(
    arabicTitle: 'الهيئة المصرية العامة للمساحة',
    region: 'مصر · السودان · ليبيا · شرق أفريقيا',
    fajrAngle: 19.5,
    ishaAngle: 17.5,
    adjustments: PrayerAdjustments(dhuhr: 1),
  ),
  karachi(
    arabicTitle: 'جامعة العلوم الإسلامية — كراتشي',
    region: 'باكستان · الهند · بنغلاديش · أفغانستان',
    fajrAngle: 18,
    ishaAngle: 18,
    adjustments: PrayerAdjustments(dhuhr: 1),
  ),
  turkey(
    arabicTitle: 'رئاسة الشؤون الدينية — تركيا',
    region: 'تركيا · البلقان',
    fajrAngle: 18,
    ishaAngle: 17,
    adjustments: PrayerAdjustments(sunrise: -7, dhuhr: 5, asr: 4, maghrib: 7),
  ),
  dubai(
    arabicTitle: 'الهيئة العامة للشؤون الإسلامية — الإمارات',
    region: 'الإمارات',
    fajrAngle: 18.2,
    ishaAngle: 18.2,
    adjustments: PrayerAdjustments(sunrise: -3, dhuhr: 3, asr: 3, maghrib: 3),
  ),
  kuwait(
    arabicTitle: 'وزارة الأوقاف — الكويت',
    region: 'الكويت',
    fajrAngle: 18,
    ishaAngle: 17.5,
  ),
  qatar(
    arabicTitle: 'وزارة الأوقاف — قطر',
    region: 'قطر',
    fajrAngle: 18,
    ishaIntervalMinutes: 90,
  ),
  jordan(
    arabicTitle: 'وزارة الأوقاف — الأردن',
    region: 'الأردن',
    fajrAngle: 18,
    ishaAngle: 18,
  ),
  northAmerica(
    arabicTitle: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)',
    region: 'الولايات المتحدة · كندا',
    fajrAngle: 15,
    ishaAngle: 15,
    adjustments: PrayerAdjustments(dhuhr: 1),
  ),
  moonsightingCommittee(
    arabicTitle: 'لجنة رؤية الهلال (تقريبي)',
    region: 'بريطانيا وأمريكا الشمالية — اختياري',
    fajrAngle: 18,
    ishaAngle: 18,
    adjustments: PrayerAdjustments(dhuhr: 5, maghrib: 3),
  ),
  singapore(
    arabicTitle: 'المجلس الإسلامي — سنغافورة',
    region: 'سنغافورة',
    fajrAngle: 20,
    ishaAngle: 18,
    adjustments: PrayerAdjustments(dhuhr: 1),
  ),
  jakim(
    arabicTitle: 'جاكيم — ماليزيا',
    region: 'ماليزيا · بروناي',
    fajrAngle: 20,
    ishaAngle: 18,
  ),
  kemenag(
    arabicTitle: 'وزارة الشؤون الدينية — إندونيسيا',
    region: 'إندونيسيا',
    fajrAngle: 20,
    ishaAngle: 18,
  ),
  tehran(
    arabicTitle: 'معهد الجيوفيزياء — جامعة طهران',
    region: 'إيران',
    fajrAngle: 17.7,
    ishaAngle: 14,
    maghribAngle: 4.5,
  ),
  morocco(
    arabicTitle: 'وزارة الأوقاف — المغرب',
    region: 'المغرب',
    fajrAngle: 19,
    ishaAngle: 17,
    adjustments: PrayerAdjustments(sunrise: -3, dhuhr: 5, maghrib: 5),
  ),
  algeria(
    arabicTitle: 'وزارة الشؤون الدينية — الجزائر',
    region: 'الجزائر',
    fajrAngle: 18,
    ishaAngle: 17,
  ),
  tunisia(
    arabicTitle: 'وزارة الشؤون الدينية — تونس',
    region: 'تونس',
    fajrAngle: 18,
    ishaAngle: 18,
  ),
  franceUoif(
    arabicTitle: 'اتحاد المنظمات الإسلامية — فرنسا',
    region: 'فرنسا',
    fajrAngle: 12,
    ishaAngle: 12,
  ),
  russia(
    arabicTitle: 'الإدارة الدينية لمسلمي روسيا',
    region: 'روسيا · بيلاروسيا',
    fajrAngle: 16,
    ishaAngle: 15,
  );

  const PrayerMethod({
    required this.arabicTitle,
    required this.region,
    required this.fajrAngle,
    this.ishaAngle = 0,
    this.ishaIntervalMinutes = 0,
    this.ramadanIshaIntervalMinutes = 0,
    this.maghribAngle = 0,
    this.adjustments = PrayerAdjustments.none,
  });

  final String arabicTitle;
  final String region;
  final double fajrAngle;
  final double ishaAngle;

  /// When > 0, Isha = Maghrib + this many minutes (Umm al-Qura, Qatar).
  final int ishaIntervalMinutes;

  /// Interval used during Ramadan when the authority lengthens it.
  final int ramadanIshaIntervalMinutes;

  /// When > 0, Maghrib is computed by angle (Tehran) rather than sunset.
  final double maghribAngle;
  final PrayerAdjustments adjustments;

  bool get ishaByInterval => ishaIntervalMinutes > 0;

  String get wire => name;

  static PrayerMethod? fromWire(String? v) {
    for (final m in PrayerMethod.values) {
      if (m.name == v) return m;
    }
    return null;
  }

  /// The convention most people in a country follow — ISO 3166-1 alpha-2.
  static PrayerMethod forCountry(String? isoCountryCode) {
    switch ((isoCountryCode ?? '').toUpperCase()) {
      case 'SA':
      case 'YE':
      case 'BH':
      case 'OM':
        return PrayerMethod.ummAlQura;
      case 'AE':
        return PrayerMethod.dubai;
      case 'KW':
        return PrayerMethod.kuwait;
      case 'QA':
        return PrayerMethod.qatar;
      case 'JO':
        return PrayerMethod.jordan;
      case 'EG':
      case 'SD':
      case 'LY':
      case 'SS':
      case 'TD':
      case 'ER':
      case 'DJ':
      case 'SO':
      case 'ET':
        return PrayerMethod.egyptian;
      case 'PK':
      case 'IN':
      case 'BD':
      case 'AF':
      case 'LK':
      case 'NP':
      case 'MV':
      case 'MM':
      case 'BT':
        return PrayerMethod.karachi;
      case 'TR':
      case 'CY':
      case 'AL':
      case 'XK':
      case 'BA':
      case 'MK':
      case 'BG':
      case 'RS':
      case 'ME':
        return PrayerMethod.turkey;
      case 'US':
      case 'CA':
      case 'MX':
        return PrayerMethod.northAmerica;
      case 'SG':
        return PrayerMethod.singapore;
      case 'MY':
      case 'BN':
        return PrayerMethod.jakim;
      case 'ID':
      case 'TL':
        return PrayerMethod.kemenag;
      case 'IR':
        return PrayerMethod.tehran;
      case 'MA':
      case 'EH':
        return PrayerMethod.morocco;
      case 'DZ':
        return PrayerMethod.algeria;
      case 'TN':
        return PrayerMethod.tunisia;
      case 'FR':
      case 'MC':
        return PrayerMethod.franceUoif;
      case 'RU':
      case 'BY':
        return PrayerMethod.russia;
      default:
        // Syria, Lebanon, Iraq, Palestine, Europe, Central Asia, the rest.
        return PrayerMethod.muslimWorldLeague;
    }
  }

  /// Countries where the Ḥanafī Asr is the common convention.
  static Madhab madhabForCountry(String? isoCountryCode) {
    switch ((isoCountryCode ?? '').toUpperCase()) {
      case 'PK':
      case 'IN':
      case 'BD':
      case 'AF':
      case 'UZ':
      case 'TJ':
      case 'KG':
      case 'KZ':
      case 'TM':
        return Madhab.hanafi;
      default:
        return Madhab.shafi;
    }
  }
}

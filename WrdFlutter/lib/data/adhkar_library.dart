import 'package:flutter/material.dart';

import '../models/gate.dart';
import '../models/wird.dart';
import '../util/ids.dart';

/// The sourced starter library — أذكار مأثورة with their references.
/// Fixed IDs so items keep their identity across launches (progress, re-adding).
/// Principle: full suras are read from the user's own mushaf — the app tracks and
/// reminds; it does not replace the mushaf. Single āyāt and adhkār appear in full.
/// NOTE: starter set for development — passes scholar review before launch.
class AdhkarCategory {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Wird> items;

  const AdhkarCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  String get id => title;
}

class AdhkarLibrary {
  AdhkarLibrary._();

  // MARK: Morning & evening

  static final AdhkarCategory morningEvening = AdhkarCategory(
    icon: Icons.wb_sunny_outlined,
    title: 'أذكار الصباح والمساء',
    subtitle: 'المأثور اليومي · بالمصادر',
    items: [
      Wird(
        id: fixedId(1),
        title: 'آية الكرسي',
        text:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        source: 'البقرة ٢٥٥',
        gate: Gate.morning,
      ),
      Wird(
        id: fixedId(2),
        title: 'الإخلاص والمعوّذتان',
        text:
            'تُقرأ سورُ الإخلاص والفلق والناس ثلاث مرات من مصحفك — والتطبيق يعدّ لك المرات.',
        source: 'أبو داود والترمذي',
        gate: Gate.morning,
        targetCount: 3,
      ),
      Wird(
        id: fixedId(3),
        title: 'أصبحنا وأصبح الملك لله',
        text:
            'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        source: 'رواه مسلم',
        gate: Gate.morning,
      ),
      Wird(
        id: fixedId(4),
        title: 'اللهم بك أصبحنا',
        text:
            'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
        source: 'رواه الترمذي',
        gate: Gate.morning,
      ),
      Wird(
        id: fixedId(5),
        title: 'سيّد الاستغفار',
        text:
            'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
        source: 'رواه البخاري',
        gate: Gate.morning,
      ),
      Wird(
        id: fixedId(6),
        title: 'سبحان الله وبحمده',
        text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        source: 'رواه مسلم',
        gate: Gate.morning,
        targetCount: 100,
      ),
      Wird(
        id: fixedId(7),
        title: 'رضيت بالله ربًّا',
        text: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا',
        source: 'رواه أبو داود',
        gate: Gate.morning,
        targetCount: 3,
      ),
    ],
  );

  // MARK: After prayer

  static final AdhkarCategory afterPrayer = AdhkarCategory(
    icon: Icons.volunteer_activism_outlined,
    title: 'أذكار بعد الصلاة',
    subtitle: 'دُبُر كل صلاة مكتوبة',
    items: [
      Wird(
        id: fixedId(11),
        title: 'الاستغفار بعد السلام',
        text:
            'أَسْتَغْفِرُ اللَّهَ (ثلاثًا) — اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
        source: 'رواه مسلم',
        gate: Gate.afterPrayer,
      ),
      Wird(
        id: fixedId(12),
        title: 'تسبيح ٣٣ · ٣٣ · ٣٣',
        text:
            'سُبْحَانَ اللَّهِ (٣٣)، الْحَمْدُ لِلَّهِ (٣٣)، اللَّهُ أَكْبَرُ (٣٣)، وَتَمَامُ الْمِئَةِ: لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        source: 'رواه مسلم',
        gate: Gate.afterPrayer,
        targetCount: 100,
      ),
      Wird(
        id: fixedId(13),
        title: 'آية الكرسي بعد الصلاة',
        text:
            'تُقرأ آية الكرسي (البقرة ٢٥٥) دُبُر كل صلاة — نصّها كاملًا في أذكار الصباح والمساء.',
        source: 'رواه النسائي وصححه الألباني',
        gate: Gate.afterPrayer,
      ),
    ],
  );

  // MARK: Sleep & waking

  static final AdhkarCategory sleep = AdhkarCategory(
    icon: Icons.bedtime_outlined,
    title: 'أذكار النوم والاستيقاظ',
    subtitle: 'قبل النوم وعند اليقظة',
    items: [
      Wird(
        id: fixedId(21),
        title: 'باسمك اللهم أموت وأحيا',
        text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        source: 'رواه البخاري',
        gate: Gate.night,
      ),
      Wird(
        id: fixedId(22),
        title: 'آية الكرسي عند النوم',
        text:
            'تُقرأ آية الكرسي قبل النوم — «لن يزال عليك من الله حافظ، ولا يقربك شيطان حتى تصبح». نصّها كاملًا في أذكار الصباح والمساء.',
        source: 'رواه البخاري',
        gate: Gate.night,
      ),
      Wird(
        id: fixedId(23),
        title: 'سورة الملك قبل النوم',
        text:
            'تُقرأ سورة الملك كاملةً من مصحفك، ثم عُد وأتمّ وِردك هنا.\n\nلماذا لا نعرض نصّ السورة؟ نُبقي تلاوة السور في المصحف — توقيرًا للنص أن يُختصر في بطاقة، وحفاظًا على صحبتك اليومية للمصحف. التطبيق يذكّرك ويحفظ إتمامك.',
        source: 'رواه الترمذي — «هي المانعة، هي المنجية»',
        gate: Gate.night,
      ),
      Wird(
        id: fixedId(24),
        title: 'الحمد لله الذي أحيانا',
        text: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        source: 'رواه البخاري',
        gate: Gate.night,
      ),
    ],
  );

  // MARK: Situational — أوراد الأحوال

  static final AdhkarCategory occasions = AdhkarCategory(
    icon: Icons.auto_awesome_outlined,
    title: 'أدعية الأحوال',
    subtitle: 'الطعام · السفر · المنزل · الخلاء…',
    items: [
      Wird(
        id: fixedId(31),
        title: 'قبل الطعام',
        text: 'بِسْمِ اللَّهِ — وإن نسيتَ في أوله فقل: بِسْمِ اللَّهِ فِي أَوَّلِهِ وَآخِرِهِ',
        source: 'رواه أبو داود والترمذي',
        gate: Gate.general,
      ),
      Wird(
        id: fixedId(32),
        title: 'بعد الطعام',
        text:
            'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
        source: 'رواه الترمذي',
        gate: Gate.general,
      ),
      Wird(
        id: fixedId(33),
        title: 'دعاء السفر',
        text:
            'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُونَ',
        source: 'رواه مسلم',
        gate: Gate.general,
      ),
      Wird(
        id: fixedId(34),
        title: 'دخول المنزل',
        text: 'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
        source: 'رواه أبو داود',
        gate: Gate.general,
      ),
      Wird(
        id: fixedId(35),
        title: 'دخول الخلاء',
        text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
        source: 'متفق عليه',
        gate: Gate.general,
      ),
      Wird(
        id: fixedId(36),
        title: 'الخروج من الخلاء',
        text: 'غُفْرَانَكَ',
        source: 'رواه أبو داود والترمذي',
        gate: Gate.general,
      ),
      Wird(
        id: fixedId(37),
        title: 'دعاء الكرب',
        text:
            'لَا إِلَٰهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَٰهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَٰهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ',
        source: 'متفق عليه',
        gate: Gate.general,
      ),
    ],
  );

  // MARK: Qurʼan awrād

  static final AdhkarCategory quran = AdhkarCategory(
    icon: Icons.menu_book_outlined,
    title: 'أوراد القرآن',
    subtitle: 'من مصحفك — والتطبيق يذكّرك ويحفظ',
    items: [
      Wird(
        id: fixedId(41),
        title: 'وِرد القرآن اليومي',
        text:
            'حدّد مقدارك اليومي — صفحات أو جزءًا أو حزبًا — واقرأه من مصحفك، ثم أتمّ وِردك هنا. تلاوة السور تبقى في المصحف؛ والتطبيق رفيقُ المداومة.',
        gate: Gate.morning,
      ),
    ],
  );

  static final List<AdhkarCategory> all = [
    morningEvening,
    afterPrayer,
    sleep,
    occasions,
    quran,
  ];

  static List<Wird> get allItems => all.expand((c) => c.items).toList();

  /// The suggested awrād a new user may choose from — nothing is imposed.
  static List<Wird> get starterAwrad => [
        morningEvening.items[0], // آية الكرسي
        morningEvening.items[3], // اللهم بك أصبحنا
        morningEvening.items[5], // سبحان الله وبحمده ×100
        afterPrayer.items[1], // تسبيح المئة
        sleep.items[2], // سورة الملك
        sleep.items[0], // باسمك اللهم
      ];

  static IconData occasionIcon(String title) {
    if (title.contains('طعام')) return Icons.restaurant_outlined;
    if (title.contains('سفر')) return Icons.flight_outlined;
    if (title.contains('منزل')) return Icons.home_outlined;
    if (title.contains('خلاء')) return Icons.water_drop_outlined;
    if (title.contains('كرب')) return Icons.favorite_outline;
    return Icons.auto_awesome_outlined;
  }
}

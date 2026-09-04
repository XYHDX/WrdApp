import 'package:flutter/material.dart';

import '../notifications/notification_manager.dart';
import '../prayer/cities.dart';
import '../prayer/location_service.dart';
import '../prayer/prayer_calculator.dart';
import '../prayer/prayer_method.dart';
import '../store/store_scope.dart';
import '../store/wrd_store.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';
import 'suggested_screen.dart';

/// Settings — you, the appearance, where you are and how your country
/// computes prayer times, and the reminders.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final WrdStore _store;
  bool _locating = false;
  bool _showAdjustments = false;

  @override
  void initState() {
    super.initState();
    _store = StoreScope.read(context);
    _name = TextEditingController(text: _store.userName);
  }

  @override
  void dispose() {
    // Whatever changed — city, method, madhhab, reminders — takes effect now.
    NotificationManager.reschedule(_store);
    _name.dispose();
    super.dispose();
  }

  Future<void> _toggleLocation(WrdStore store, bool on) async {
    if (!on) {
      store.useDeviceLocation = false;
      return;
    }
    setState(() => _locating = true);
    final outcome = await store.refreshDeviceLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (outcome != LocationOutcome.resolved) {
      final message = outcome == LocationOutcome.denied
          ? 'لم يُسمح بالوصول إلى الموقع — اسمح به من إعدادات النظام، أو اختر مدينتك يدويًا.'
          : 'تعذّر تحديد الموقع الآن — اختر مدينتك يدويًا أو حاول لاحقًا.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggleReminders(WrdStore store, bool on) async {
    if (!on) {
      store.remindersEnabled = false;
      return;
    }
    final granted = await NotificationManager.requestPermission();
    if (!mounted) return;
    if (granted) {
      store.remindersEnabled = true;
    } else {
      store.remindersEnabled = false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('التنبيهات غير مسموحة'),
          content: const Text('اسمح بالتنبيهات لتطبيق وِرْد من إعدادات النظام حتى نذكّرك بأورادك.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا'))],
        ),
      );
    }
  }

  Future<void> _pickCity(WrdStore store) async {
    final c = WrdColors.of(context);
    final city = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('اختر مدينتك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
            const SizedBox(height: 12),
            for (final city in City.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wash(
                  cornerRadius: 12,
                  strong: city.name == store.city.name,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () => Navigator.pop(ctx, city),
                  child: Row(
                    children: [
                      Expanded(child: Text(city.arabicName, style: TextStyle(fontSize: 15, color: c.ink))),
                      Text(PrayerMethod.forCountry(city.countryCode).arabicTitle,
                          style: TextStyle(fontSize: 11, color: c.faint)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (city != null) {
      store.city = city;
      store.useDeviceLocation = false;
    }
  }

  Future<void> _pickMethod(WrdStore store) async {
    final c = WrdColors.of(context);
    final auto = PrayerMethod.forCountry(store.countryCode);
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('طريقة حساب المواقيت',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
            const SizedBox(height: 4),
            Text('تُختار تلقائيًا بحسب بلدك — وتستطيع تثبيت طريقةٍ بعينها.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.muted)),
            const SizedBox(height: 12),
            _MethodOption(
              title: 'تلقائي حسب بلدك',
              subtitle: 'الآن: ${auto.arabicTitle}',
              selected: store.methodOverride == null,
              onTap: () => Navigator.pop(ctx, 'auto'),
            ),
            const SizedBox(height: 10),
            for (final method in PrayerMethod.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _MethodOption(
                  title: method.arabicTitle,
                  subtitle: '${method.region} · فجر ${_angle(method.fajrAngle)}° · '
                      '${method.ishaByInterval ? 'عشاء بعد المغرب بـ${arabicNumber(method.ishaIntervalMinutes)} د' : 'عشاء ${_angle(method.ishaAngle)}°'}',
                  selected: store.methodOverride == method,
                  onTap: () => Navigator.pop(ctx, method),
                ),
              ),
          ],
        ),
      ),
    );
    if (result == 'auto') {
      store.methodOverride = null;
    } else if (result is PrayerMethod) {
      store.methodOverride = result;
    }
  }

  static String _angle(double a) {
    final s = a == a.roundToDouble() ? a.toInt().toString() : a.toString();
    return s.split('').map((ch) => int.tryParse(ch) == null ? (ch == '.' ? '٫' : ch) : arabicNumber(int.parse(ch))).join();
  }

  Future<void> _pickMadhab(WrdStore store) async {
    final auto = PrayerMethod.madhabForCountry(store.countryCode);
    final result = await choose<Object>(
      context,
      title: 'حساب العصر',
      options: [
        ('تلقائي حسب بلدك — ${auto.arabicTitle}', 'auto'),
        for (final m in Madhab.values) (m.arabicTitle, m),
      ],
    );
    if (result == 'auto') {
      store.madhabOverride = null;
    } else if (result is Madhab) {
      store.madhabOverride = result;
    }
  }

  Future<void> _pickHighLat(WrdStore store) async {
    final result = await choose<HighLatitudeRule>(
      context,
      title: 'عند العروض العالية (حين لا يغيب الشفق)',
      options: [for (final r in HighLatitudeRule.values) (r.arabicTitle, r)],
    );
    if (result != null) store.highLatitudeRule = result;
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final prayers = store.todayPrayers;
    final adj = store.userAdjustments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تمّ', style: TextStyle(color: c.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // أنت --------------------------------------------------------------
          const SectionLabel('أنت'),
          const SizedBox(height: 8),
          _Group(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: WrdField(
                placeholder: 'اسمك الكريم',
                controller: _name,
                onChanged: (v) => store.userName = v.trim(),
              ),
            ),
            const Divider(),
            _SwitchRow(label: 'خطٌّ كبير — راحةً للعين', value: store.largeText, onChanged: (v) => store.largeText = v),
          ]),

          // المظهر -----------------------------------------------------------
          const SizedBox(height: 18),
          const SectionLabel('المظهر'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final theme in WrdTheme.values)
                  _Choice(
                    label: theme.arabicTitle,
                    selected: store.theme == theme,
                    onTap: () => store.theme = theme,
                  ),
              ],
            ),
          ),

          // الموقع والمواقيت ---------------------------------------------------
          const SizedBox(height: 18),
          const SectionLabel('الموقع ومواقيت الصلاة'),
          const SizedBox(height: 8),
          _Group(children: [
            _SwitchRow(
              label: 'تحديد الموقع تلقائيًا',
              subtitle: store.useDeviceLocation
                  ? 'الموقع الحالي: ${store.placeLabel} (${store.countryCode})'
                  : 'يُستخدم لاختيار طريقة بلدك — ولا يغادر جهازك',
              value: store.useDeviceLocation,
              busy: _locating,
              onChanged: (v) => _toggleLocation(store, v),
            ),
            if (!store.useDeviceLocation) ...[
              const Divider(),
              _TapRow(label: 'المدينة', value: store.city.arabicName, onTap: () => _pickCity(store)),
            ],
            const Divider(),
            _TapRow(
              label: 'طريقة الحساب',
              value: store.effectiveMethod.arabicTitle,
              hint: store.methodOverride == null ? 'تلقائي حسب البلد' : 'مثبّتة يدويًا',
              onTap: () => _pickMethod(store),
            ),
            const Divider(),
            _TapRow(
              label: 'العصر',
              value: store.effectiveMadhab == Madhab.hanafi ? 'الحنفي' : 'الجمهور',
              hint: store.madhabOverride == null ? 'تلقائي حسب البلد' : 'مثبّت يدويًا',
              onTap: () => _pickMadhab(store),
            ),
            const Divider(),
            _TapRow(
              label: 'العروض العالية',
              value: store.highLatitudeRule.arabicTitle,
              onTap: () => _pickHighLat(store),
            ),
            const Divider(),
            GestureDetector(
              onTap: () => setState(() => _showAdjustments = !_showAdjustments),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('تعديل دقيق بالدقائق', style: TextStyle(fontSize: 15, color: c.ink))),
                    Icon(_showAdjustments ? Icons.expand_less : Icons.expand_more, color: c.muted),
                  ],
                ),
              ),
            ),
            if (_showAdjustments)
              for (final prayer in PrayerName.values)
                _AdjustRow(
                  label: prayer.arabicName,
                  value: _adjFor(adj, prayer),
                  onChanged: (v) => store.userAdjustments = _withAdj(adj, prayer, v),
                ),
          ]),
          const SizedBox(height: 10),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Text('مواقيت اليوم — ${store.placeLabel}',
                    style: TextStyle(fontSize: 12, color: c.goldDeep, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                for (final prayer in PrayerName.values)
                  if (prayers.time(prayer) != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(prayer.arabicName,
                              style: TextStyle(fontSize: 14, color: prayer == PrayerName.sunrise ? c.faint : c.ink)),
                          const Spacer(),
                          Text(timeString(prayers.time(prayer)!),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: prayer == PrayerName.sunrise ? c.faint : c.goldDeep)),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تُحسب المواقيت على جهازك بلا إنترنت، بطريقة الهيئة المعتمدة في بلدك (${store.effectiveMethod.arabicTitle}). '
            'إن اختلفت دقيقة أو دقيقتان عن تقويم مسجدك فاستعمل التعديل الدقيق.',
            style: TextStyle(fontSize: 12, color: c.muted, height: 1.6),
          ),

          // التذكير ----------------------------------------------------------
          const SizedBox(height: 18),
          const SectionLabel('التذكير'),
          const SizedBox(height: 8),
          _Group(children: [
            _SwitchRow(
              label: 'ذكّرني بأورادي',
              value: store.remindersEnabled,
              onChanged: (v) => _toggleReminders(store, v),
            ),
            if (store.remindersEnabled) ...[
              const Divider(),
              _SwitchRow(label: 'نداء عند كل صلاة', value: store.adhanEnabled, onChanged: (v) => store.adhanEnabled = v),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'تنبيه عند دخول وقت كل صلاة، وتذكيرٌ بوِرد الصباح بعد الفجر وبالوِرد الليلي بعد العشاء — كلها بمواقيت ${store.placeLabel}.',
                  style: TextStyle(fontSize: 12, color: c.muted, height: 1.6),
                ),
              ),
            ],
          ]),

          // الأوراد ----------------------------------------------------------
          const SizedBox(height: 18),
          const SectionLabel('الأوراد'),
          const SizedBox(height: 8),
          _Group(children: [
            GestureDetector(
              onTap: () => showWrdSheet(context, const SuggestedScreen()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_outlined, color: c.gold, size: 20),
                    const SizedBox(width: 10),
                    Text('الأوراد المقترحة — اختر منها', style: TextStyle(fontSize: 15, color: c.gold)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('مجموعة مختارة للبداية — تختار منها ما يناسبك، ولا شيء يُفرض.',
                  style: TextStyle(fontSize: 12, color: c.muted)),
            ),
          ]),

          // عن وِرْد ----------------------------------------------------------
          const SizedBox(height: 18),
          const SectionLabel('عن وِرْد'),
          const SizedBox(height: 8),
          _Group(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text('وِردُكَ نُورُك', style: TextStyle(fontSize: 15, color: c.gold)),
                  const Spacer(),
                  Text('النسخة ٠٫٨ · Flutter', style: TextStyle(fontSize: 12, color: c.faint)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('لا إعلانات، ولا بيع بيانات — عبادتُك لك وحدك.',
                  style: TextStyle(fontSize: 12, color: c.muted)),
            ),
          ]),
        ],
      ),
    );
  }

  static int _adjFor(PrayerAdjustments a, PrayerName p) {
    switch (p) {
      case PrayerName.fajr:
        return a.fajr;
      case PrayerName.sunrise:
        return a.sunrise;
      case PrayerName.dhuhr:
        return a.dhuhr;
      case PrayerName.asr:
        return a.asr;
      case PrayerName.maghrib:
        return a.maghrib;
      case PrayerName.isha:
        return a.isha;
    }
  }

  static PrayerAdjustments _withAdj(PrayerAdjustments a, PrayerName p, int v) {
    return PrayerAdjustments(
      fajr: p == PrayerName.fajr ? v : a.fajr,
      sunrise: p == PrayerName.sunrise ? v : a.sunrise,
      dhuhr: p == PrayerName.dhuhr ? v : a.dhuhr,
      asr: p == PrayerName.asr ? v : a.asr,
      maghrib: p == PrayerName.maghrib ? v : a.maghrib,
      isha: p == PrayerName.isha ? v : a.isha,
    );
  }
}

// MARK: - Pieces

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wash(
      cornerRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, color: c.ink)),
                if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11, color: c.muted)),
              ],
            ),
          ),
          if (busy)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final VoidCallback onTap;
  const _TapRow({required this.label, required this.value, this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 15, color: c.ink)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value,
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.goldDeep)),
                  if (hint != null) Text(hint!, style: TextStyle(fontSize: 11, color: c.faint)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_left, size: 18, color: c.faint),
          ],
        ),
      ),
    );
  }
}

class _AdjustRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _AdjustRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final text = value == 0 ? '٠' : (value > 0 ? '+${arabicNumber(value)}' : '−${arabicNumber(-value)}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: c.muted)),
          const Spacer(),
          WashIconButton(icon: Icons.remove, size: 28, onTap: () => onChanged((value - 1).clamp(-60, 60).toInt())),
          SizedBox(
            width: 48,
            child: Text('$text د',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value == 0 ? c.faint : c.gold)),
          ),
          WashIconButton(icon: Icons.add, size: 28, onTap: () => onChanged((value + 1).clamp(-60, 60).toInt())),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: selected ? c.gold : c.goldWash, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? c.ground : c.gold)),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _MethodOption({required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Wash(
      cornerRadius: 14,
      strong: selected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 20, color: selected ? c.gold : c.faint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, color: c.ink)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

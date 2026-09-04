import 'package:flutter/material.dart';

import '../prayer/cities.dart';
import '../prayer/location_service.dart';
import '../prayer/prayer_method.dart';
import '../store/store_scope.dart';
import '../theme/wrd_colors.dart';
import '../widgets/components.dart';

/// First light — one small welcome that makes the app personal: your name,
/// where you are (for your country's prayer times), and comfortable type.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  City _city = City.defaultCity;
  bool _isElder = false;
  bool _locating = false;
  ResolvedLocation? _located;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final (outcome, location) = await LocationService.resolve();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _located = location;
    });
    if (outcome != LocationOutcome.resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديد الموقع — اختر مدينتك من القائمة، ويمكنك المحاولة لاحقًا من الإعدادات.')),
      );
    }
  }

  Future<void> _pickCity() async {
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
            for (final city in City.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wash(
                  cornerRadius: 12,
                  strong: city.name == _city.name,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () => Navigator.pop(ctx, city),
                  child: Text(city.arabicName, style: TextStyle(fontSize: 15, color: c.ink)),
                ),
              ),
          ],
        ),
      ),
    );
    if (city != null) {
      setState(() {
        _city = city;
        _located = null;
      });
    }
  }

  void _start() {
    final store = StoreScope.read(context);
    store.userName = _name.text.trim();
    store.city = _city;
    if (_located != null) {
      store.resolvedLocation = _located;
      store.useDeviceLocation = true;
    } else {
      store.useDeviceLocation = false;
    }
    store.largeText = _isElder;
    store.hasOnboarded = true;
    Haptics.success();
  }

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final method = PrayerMethod.forCountry(_located?.countryCode ?? _city.countryCode);
    return Scaffold(
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_isElder ? 1.3 : 1.0)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            children: [
              const Center(child: RubElHizb(size: 52)),
              const SizedBox(height: 10),
              Text('وِرْد',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: c.ink)),
              Text('وِردُكَ نُورُك', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: c.gold)),
              const SizedBox(height: 28),

              const _Label('اسمك الكريم'),
              const SizedBox(height: 6),
              Wash(
                cornerRadius: 14,
                padding: const EdgeInsets.all(14),
                child: WrdField(placeholder: 'مثال: يحيى', controller: _name),
              ),
              const SizedBox(height: 16),

              const _Label('موقعك — لمواقيت الصلاة بطريقة بلدك'),
              const SizedBox(height: 6),
              Wash(
                cornerRadius: 14,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GoldPill(
                            label: _located != null
                                ? (_located!.placeName ?? 'تمّ تحديد موقعك')
                                : (_locating ? 'جارٍ التحديد…' : 'حدّد موقعي تلقائيًا'),
                            icon: _located != null ? Icons.check : Icons.my_location,
                            filled: _located == null,
                            onTap: _locating ? null : _locate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCity,
                      child: Row(
                        children: [
                          Text(_located != null ? 'أو اختر مدينة بدلًا منه' : 'أو اختر مدينتك:',
                              style: TextStyle(fontSize: 13, color: c.muted)),
                          const SizedBox(width: 6),
                          if (_located == null)
                            Text(_city.arabicName,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.gold)),
                          Icon(Icons.expand_more, size: 18, color: c.faint),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('طريقة الحساب: ${method.arabicTitle}', style: TextStyle(fontSize: 11, color: c.faint)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const _Label('العمر'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _Segment(label: 'دون الخمسين', selected: !_isElder, onTap: () => setState(() => _isElder = false))),
                  const SizedBox(width: 8),
                  Expanded(child: _Segment(label: 'خمسون فما فوق', selected: _isElder, onTap: () => setState(() => _isElder = true))),
                ],
              ),
              const SizedBox(height: 6),
              Text('لمن بلغ الخمسين نُكبّر الخط تلقائيًا — راحةً للعين', style: TextStyle(fontSize: 12, color: c.muted)),
              const SizedBox(height: 32),

              GoldPill(label: 'ابدأ رحلة النور', expand: true, onTap: _start),
              const SizedBox(height: 14),
              Text('هذا التطبيق مجانيٌّ تمامًا — وتكفينا دعوةٌ صادقةٌ من قلبك 🤍',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.faint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: WrdColors.of(context).goldDeep));
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.gold : c.wash,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? c.ground : c.ink)),
      ),
    );
  }
}

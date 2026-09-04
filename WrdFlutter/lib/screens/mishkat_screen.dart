import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../store/store_scope.dart';
import '../store/wrd_store.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../util/dates.dart';
import '../widgets/components.dart';

/// The mishkāt — the illuminated record. Light is never taken away.
class MishkatScreen extends StatefulWidget {
  const MishkatScreen({super.key});

  @override
  State<MishkatScreen> createState() => _MishkatScreenState();
}

class _MishkatScreenState extends State<MishkatScreen> {
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(WrdStore store) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // Render the off-screen card to a PNG and share it as an image.
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no boundary');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no bytes');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mishkat.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'مشكاتي — ${HijriDate.currentMonth()} · وِردُكَ نُورُك',
      );
    } catch (_) {
      await Share.share(
        'وِردُكَ نُورُك — ${arabicNumber(store.litDaysAllTime)} يومًا مضيئًا في مشكاتي 🕯 تطبيق وِرْد',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final monthDays = HijriDate.currentMonthDays();
    final todayDay = HijriDate.currentHijriDay();
    final litFlags = monthDays.map((d) => store.isLit(dayKey(d))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشكاة'),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share, color: c.gold),
            onPressed: _sharing ? null : () => _share(store),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text('${HijriDate.currentMonth()} · نورُ الشهر', style: TextStyle(fontSize: 12, color: c.muted)),
              const SizedBox(height: 14),
              Wash(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: monthDays.length,
                      itemBuilder: (context, i) => _Lamp(
                        isLit: litFlags[i],
                        isToday: i + 1 == todayDay,
                        onTap: () => showWrdSheet(
                          context,
                          DayDetailSheet(dayKey: dayKey(monthDays[i])),
                          tall: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('كل مصباحٍ يومٌ أتممتَ فيه أورادك — النور لا يُنتزع أبدًا',
                        style: TextStyle(fontSize: 11, color: c.faint)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(arabicNumber(store.litDaysAllTime), 'يومٌ مضيء'),
                  const SizedBox(width: 10),
                  _Stat(arabicNumber(store.totalCompletedAllTime), 'وِردٌ أُتمّ'),
                  const SizedBox(width: 10),
                  _Stat(arabicNumber(store.awrad.length), 'وِردٌ محفوظ'),
                ],
              ),
              const SizedBox(height: 14),
              Wash(
                cornerRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: c.goldDeep, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('شموس الختمات تُذهَّب هنا مع حلقات الختمة — قريبًا بإذن الله',
                          style: TextStyle(fontSize: 12, color: c.muted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Off-screen share card (rendered but not visible).
          Positioned(
            left: -2000,
            top: 0,
            child: RepaintBoundary(
              key: _shareKey,
              child: MishkatShareCard(monthName: HijriDate.currentMonth(), litFlags: litFlags),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lamp extends StatelessWidget {
  final bool isLit;
  final bool isToday;
  final VoidCallback onTap;
  const _Lamp({required this.isLit, required this.isToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLit ? c.goldWash : Colors.transparent,
          border: isToday ? Border.all(color: c.gold, width: 1.5) : null,
        ),
        child: Center(
          child: Container(
            width: isLit ? 12 : 9,
            height: isLit ? 12 : 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLit ? c.gold : c.washStrong,
              boxShadow: isLit ? [BoxShadow(color: c.gold.withValues(alpha: 0.5), blurRadius: 6)] : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Expanded(
      child: Wash(
        cornerRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c.gold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

// MARK: - Day detail

class DayDetailSheet extends StatelessWidget {
  final String dayKey;
  const DayDetailSheet({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final record = store.days[dayKey];
    final completed = record == null ? <String>[] : store.awrad.where(record.isDone).map((w) => w.title).toList();
    final date = dateFromDayKey(dayKey);
    final title = date == null ? dayKey : HijriDate.format(date);
    final lit = store.isLit(dayKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink)),
          const SizedBox(height: 10),
          if (lit)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: c.gold),
                const SizedBox(width: 6),
                Text('يومٌ مضيء — اكتملت الأوراد',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.gold)),
              ],
            )
          else if (completed.isEmpty)
            Text('لا أوراد مسجّلة في هذا اليوم', style: TextStyle(fontSize: 14, color: c.muted))
          else
            Text('أُتمّ فيه ${arabicNumber(completed.length)} وِردًا', style: TextStyle(fontSize: 14, color: c.muted)),
          const SizedBox(height: 14),
          if (completed.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: completed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) => Wash(
                  cornerRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: c.gold),
                      const SizedBox(width: 10),
                      Expanded(child: Text(completed[i], style: TextStyle(fontSize: 14, color: c.ink))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// MARK: - Shareable render — the month as an illuminated card

class MishkatShareCard extends StatelessWidget {
  final String monthName;
  final List<bool> litFlags;
  const MishkatShareCard({super.key, required this.monthName, required this.litFlags});

  static const _ground = Color(0xFF1D1710);
  static const _gold = Color(0xFFD6B25E);
  static const _goldDeep = Color(0xFFB08D36);
  static const _parchmentText = Color(0xFFF0E6D2);
  static const _mutedText = Color(0xFFA79878);

  @override
  Widget build(BuildContext context) {
    final lit = litFlags.where((f) => f).length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 390,
        padding: const EdgeInsets.all(28),
        color: _ground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('مشكاتي',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: _parchmentText)),
            const SizedBox(height: 4),
            Text(monthName, style: const TextStyle(fontSize: 14, color: _mutedText)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final flag in litFlags)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: Container(
                          width: flag ? 13 : 9,
                          height: flag ? 13 : 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: flag ? _gold : const Color(0xFF54401F).withValues(alpha: 0.45),
                            boxShadow: flag
                                ? [BoxShadow(color: _gold.withValues(alpha: 0.6), blurRadius: 5)]
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('${arabicNumber(lit)} يومًا مضيئًا',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _gold)),
            const SizedBox(height: 3),
            const Text('وِردُكَ نُورُك — تطبيق وِرْد', style: TextStyle(fontSize: 12, color: _goldDeep)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/adhkar_library.dart';
import '../models/gate.dart';
import '../models/wird.dart';
import '../store/store_scope.dart';
import '../store/wrd_store.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';
import 'counter_screen.dart';
import 'settings_screen.dart';
import 'suggested_screen.dart';

/// اليوم — one screen. Gates ordered by the founder's rule: morning leads
/// until finished, then after-prayer, and after ʿIshāʼ the night wird leads.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final order = store.gateOrder();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اليوم'),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: c.muted),
            onPressed: () => showWrdSheet(context, const SettingsScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _Header(store: store),
                const SizedBox(height: 14),
                _HeroCard(gate: order[0]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 1; i < order.length; i++) ...[
                      if (i > 1) const SizedBox(width: 12),
                      Expanded(child: _CompactTile(gate: order[i])),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                const _GeneralRow(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'هذا التطبيق مجانيٌّ تمامًا — وتكفينا دعوةٌ صادقةٌ من قلبك لمؤسسه يحيى ضميرية 🤍',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.faint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final WrdStore store;
  const _Header({required this.store});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final next = store.todayPrayers.nextPrayer();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.userName.isNotEmpty)
                Text(
                  'حيّاك الله يا ${store.userName} 🤍',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.gold),
                ),
              Text(HijriDate.today(), style: TextStyle(fontSize: 14, color: c.muted)),
            ],
          ),
        ),
        if (store.todayIsLit)
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: c.gold),
              const SizedBox(width: 4),
              Text('أُضيءَ اليوم',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.gold)),
            ],
          )
        else if (next != null)
          Text(
            '${next.$1.arabicName} ${timeString(next.$2)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.goldDeep),
          ),
      ],
    );
  }
}

// MARK: Hero — the leading gate

class _HeroCard extends StatelessWidget {
  final Gate gate;
  const _HeroCard({required this.gate});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final items = store.awradIn(gate);
    final preview = items.take(3).toList();

    return Wash(
      padding: const EdgeInsets.all(16),
      shadow: true,
      onTap: () => GateDetailScreen.open(context, gate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GateRing(progress: store.progress(gate), size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gate.arabicTitle,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: c.ink)),
                    const SizedBox(height: 3),
                    Text(gate.subtitle, style: TextStyle(fontSize: 14, color: c.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: c.faint),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyGateHint()
          else ...[
            for (final wird in preview) ...[
              _HeroRow(wird: wird),
              const SizedBox(height: 7),
            ],
            if (items.length > preview.length)
              Text(
                'و${arabicNumber(items.length - preview.length)} أخرى — انقر للمزيد',
                style: TextStyle(fontSize: 13, color: c.faint),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyGateHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text('لا أوراد هنا — تصفّح المكتبة وأضِف،', style: TextStyle(fontSize: 14, color: c.faint)),
        GestureDetector(
          onTap: () => showWrdSheet(context, const SuggestedScreen()),
          child: Text('أو اختر من المقترحة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.gold)),
        ),
      ],
    );
  }
}

class _HeroRow extends StatelessWidget {
  final Wird wird;
  const _HeroRow({required this.wird});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final done = store.isDone(wird);
    return Wash(
      strong: !done,
      cornerRadius: 13,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => CounterScreen.open(context, wird),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (done) {
                store.resetToday(wird);
                Haptics.light();
              } else {
                store.markDone(wird);
                Haptics.success();
              }
            },
            child: Icon(
              done ? Icons.check_circle_outline : Icons.circle_outlined,
              size: 24,
              color: done ? c.gold : c.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              wird.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: done ? c.muted : c.ink),
            ),
          ),
          if (wird.targetCount > 1)
            Text(
              '${arabicNumber(store.countFor(wird))}/${arabicNumber(wird.targetCount)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.goldDeep),
            ),
        ],
      ),
    );
  }
}

// MARK: Compact tiles

class _CompactTile extends StatelessWidget {
  final Gate gate;
  const _CompactTile({required this.gate});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final items = store.awradIn(gate);
    final done = items.where(store.isDone).length;
    return Wash(
      cornerRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: () => GateDetailScreen.open(context, gate),
      child: Column(
        children: [
          GateRing(progress: store.progress(gate), size: 46),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(gate.arabicTitle,
                maxLines: 1,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
          ),
          const SizedBox(height: 2),
          Text('${arabicNumber(done)} من ${arabicNumber(items.length)}',
              style: TextStyle(fontSize: 13, color: c.muted)),
        ],
      ),
    );
  }
}

// MARK: أوراد الأحوال

class _GeneralRow extends StatelessWidget {
  const _GeneralRow();

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(Gate.general.arabicTitle),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AdhkarLibrary.occasions.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final wird = AdhkarLibrary.occasions.items[i];
              return GestureDetector(
                onTap: () => CounterScreen.open(context, wird),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: c.wash, shape: BoxShape.circle),
                        child: Icon(AdhkarLibrary.occasionIcon(wird.title), color: c.gold, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(wird.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: c.muted)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// MARK: - Gate detail sheet

class GateDetailScreen extends StatelessWidget {
  final Gate gate;
  const GateDetailScreen({super.key, required this.gate});

  static Future<void> open(BuildContext context, Gate gate) =>
      showWrdSheet(context, GateDetailScreen(gate: gate));

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final items = store.awradIn(gate);
    return Scaffold(
      appBar: AppBar(
        title: Text(gate.arabicTitle, style: const TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تمّ', style: TextStyle(color: c.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('لا أوراد في هذه البوابة', style: TextStyle(fontSize: 16, color: c.muted)),
                    const SizedBox(height: 8),
                    Text('تصفّح المكتبة وأضِف ما تحب — وتختار البوابة عند الإضافة',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.faint)),
                    const SizedBox(height: 16),
                    GoldPill(
                      label: 'الأوراد المقترحة — اختر منها',
                      icon: Icons.auto_fix_high_outlined,
                      filled: false,
                      onTap: () => showWrdSheet(context, const SuggestedScreen()),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _GateRow(wird: items[i]),
            ),
    );
  }
}

class _GateRow extends StatelessWidget {
  final Wird wird;
  const _GateRow({required this.wird});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final done = store.isDone(wird);
    return Wash(
      strong: !done,
      cornerRadius: 13,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      onTap: () => CounterScreen.open(context, wird),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (done) {
                store.resetToday(wird);
                Haptics.light();
              } else {
                store.markDone(wird);
                Haptics.success();
              }
            },
            child: Icon(done ? Icons.check_circle_outline : Icons.circle_outlined,
                size: 24, color: done ? c.gold : c.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wird.title, style: TextStyle(fontSize: 16, color: done ? c.muted : c.ink)),
                if (wird.targetCount > 1)
                  Text('${arabicNumber(store.countFor(wird))} من ${arabicNumber(wird.targetCount)}',
                      style: TextStyle(fontSize: 13, color: c.faint)),
              ],
            ),
          ),
          if (!done)
            Text(wird.targetCount > 1 ? 'سبّح' : 'اقرأ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.gold)),
        ],
      ),
    );
  }
}

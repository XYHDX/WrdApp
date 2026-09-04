import 'package:flutter/material.dart';

import '../models/gate.dart';
import '../models/wird.dart';
import '../notifications/notification_manager.dart';
import '../store/store_scope.dart';
import '../store/wrd_store.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';
import 'compose_screen.dart';
import 'counter_screen.dart';
import 'suggested_screen.dart';

/// أورادي — the private area. The user's own awrād, kept on this device only,
/// each showing whether it was READ today or not. The state resets with the
/// day; finishing the counter marks it read automatically; a tap on the mark
/// toggles it by hand. Read awrād sink to the bottom of their gate.
class MyAwradScreen extends StatelessWidget {
  const MyAwradScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('أورادي'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: c.gold),
            onPressed: () => showWrdSheet(context, const ComposeScreen()),
          ),
        ],
      ),
      body: store.awrad.isEmpty ? const _EmptyState() : _AwradList(store: store),
    );
  }
}

class _AwradList extends StatelessWidget {
  final WrdStore store;
  const _AwradList({required this.store});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: c.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'هذه المساحة خاصة بك — أورادك تبقى على جهازك، ولا يطّلع عليها أحد.',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ReadProgressCard(store: store),
        const SizedBox(height: 6),
        for (final gate in Gate.values) ...[
          if (store.awradIn(gate).isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                SectionLabel(gate.arabicTitle),
                const Spacer(),
                Text(
                  '${arabicNumber(store.awradIn(gate).where(store.isRead).length)} / ${arabicNumber(store.awradIn(gate).length)} مقروء',
                  style: TextStyle(fontSize: 12, color: c.faint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final wird in _sorted(store, gate)) ...[
              _WirdRow(wird: wird),
              const SizedBox(height: 6),
            ],
          ],
        ],
        const SizedBox(height: 16),
        Center(
          child: GoldPill(
            label: 'الأوراد المقترحة — اختر منها',
            icon: Icons.auto_fix_high_outlined,
            filled: false,
            onTap: () => showWrdSheet(context, const SuggestedScreen()),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'انقر الدائرة لتعليم الوِرد مقروءًا أو غير مقروء — ويتجدّد الحساب مع كل يوم. احذف بلمسة سلة المهملات — والنور الذي كسبتَه يبقى لك.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: c.faint),
        ),
      ],
    );
  }

  /// Unread first (in saved order), read ones sink to the bottom.
  static List<Wird> _sorted(WrdStore store, Gate gate) {
    final items = store.awradIn(gate);
    return [
      ...items.where((w) => !store.isRead(w)),
      ...items.where(store.isRead),
    ];
  }
}

/// "قرأتَ ٣ من ٧ اليوم" — the day's reading at a glance.
class _ReadProgressCard extends StatelessWidget {
  final WrdStore store;
  const _ReadProgressCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final total = store.awrad.length;
    final read = store.readTodayCount;
    final all = total > 0 && read >= total;
    return Wash(
      padding: const EdgeInsets.all(14),
      cornerRadius: 18,
      child: Row(
        children: [
          GateRing(progress: total == 0 ? 0 : read / total, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  all ? 'قرأتَ أورادك كلها اليوم — تقبّل الله' : 'قرأتَ ${arabicNumber(read)} من ${arabicNumber(total)} اليوم',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: all ? c.gold : c.ink),
                ),
                const SizedBox(height: 2),
                Text(HijriDate.today(), style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          if (all) Icon(Icons.auto_awesome, color: c.gold, size: 20),
        ],
      ),
    );
  }
}

class _WirdRow extends StatelessWidget {
  final Wird wird;
  const _WirdRow({required this.wird});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final read = store.isRead(wird);
    final readAt = store.readAt(wird);

    return Wash(
      cornerRadius: 14,
      strong: !read,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => CounterScreen.open(context, wird),
      child: Row(
        children: [
          // The read mark — tap to toggle by hand.
          GestureDetector(
            onTap: () {
              store.toggleRead(wird);
              if (read) {
                Haptics.light();
              } else {
                Haptics.success();
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                read ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(read),
                size: 26,
                color: read ? c.gold : c.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        wird.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: read ? c.muted : c.ink,
                          decoration: read ? TextDecoration.lineThrough : null,
                          decorationColor: c.faint,
                        ),
                      ),
                    ),
                    if (wird.isCustom) ...[const SizedBox(width: 6), const Tag('خاص')],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Read state, in words — "مقروء ٦:٤٢" or "لم يُقرأ بعد".
                    Icon(read ? Icons.done_all : Icons.radio_button_unchecked,
                        size: 11, color: read ? c.gold : c.faint),
                    const SizedBox(width: 4),
                    Text(
                      read
                          ? (readAt != null ? 'مقروء ${timeString(readAt)}' : 'مقروء')
                          : 'لم يُقرأ بعد',
                      style: TextStyle(fontSize: 11, color: read ? c.gold : c.faint),
                    ),
                    if (wird.source != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(wird.source!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: c.muted)),
                      ),
                    ],
                    if (wird.reminderMinutes != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.notifications_none, size: 11, color: c.goldDeep),
                      const SizedBox(width: 2),
                      Text(minutesTimeString(wird.reminderMinutes!),
                          style: TextStyle(fontSize: 11, color: c.goldDeep)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (wird.targetCount > 1) ...[
            const SizedBox(width: 8),
            Text(
              read
                  ? '×${arabicNumber(wird.targetCount)}'
                  : '${arabicNumber(store.countFor(wird))}/${arabicNumber(wird.targetCount)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.gold),
            ),
          ],
          const SizedBox(width: 10),
          WashIconButton(
            icon: Icons.delete_outline,
            color: c.faint,
            size: 30,
            onTap: () => _confirmDelete(context, store, wird),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WrdStore store, Wird wird) async {
    final ok = await confirm(
      context,
      title: 'حذف الوِرد؟',
      message: 'يُحذف «${wird.title}» من أورادك — والنور الذي كسبتَه به يبقى لك.',
      confirmLabel: 'احذف',
      cancelLabel: 'إبقاء',
      destructive: true,
    );
    if (!ok) return;
    store.remove(wird);
    NotificationManager.reschedule(store);
    Haptics.light();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RubElHizb(size: 40),
            const SizedBox(height: 14),
            Text('مساحتك تبدأ فارغة — كما ينبغي',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: c.ink)),
            const SizedBox(height: 8),
            Text(
              'تصفّح المكتبة وأضِف ما يناسبك،\nأو أنشئ وِردك الخاص من الزر أعلاه',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.muted, height: 1.6),
            ),
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
    );
  }
}

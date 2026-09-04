import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../circles/circle_codec.dart';
import '../models/khatma.dart';
import '../store/store_scope.dart';
import '../store/wrd_store.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';

/// الحلقات — khatma circles. The creator controls the split; invites travel as
/// WhatsApp-friendly codes; each member marks only their own ajzāʼ and shares a
/// small progress code back — so everyone sees the khatma move without asking.
class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحلقات'),
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined, color: c.goldDeep),
            tooltip: 'انضمّ برمز',
            onPressed: () => showWrdSheet(context, const JoinCircleSheet(), tall: false),
          ),
          IconButton(
            icon: Icon(Icons.add, color: c.gold),
            tooltip: 'أنشئ حلقة',
            onPressed: () => showWrdSheet(context, const CreateCircleSheet()),
          ),
        ],
      ),
      body: store.circles.isEmpty ? const _EmptyState() : _CirclesList(store: store),
    );
  }
}

class _CirclesList extends StatelessWidget {
  final WrdStore store;
  const _CirclesList({required this.store});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        for (final circle in store.circles) ...[
          _CircleRow(circle: circle),
          const SizedBox(height: 10),
        ],
        Text('الدعوة والتحديث برموزٍ تُلصق في واتساب — والمزامنة التلقائية قادمة بإذن الله',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: c.faint)),
      ],
    );
  }
}

class _CircleRow extends StatelessWidget {
  final KhatmaCircle circle;
  const _CircleRow({required this.circle});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Wash(
      cornerRadius: 18,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: circle.id)),
      ),
      child: Row(
        children: [
          GateRing(
            progress: circle.progress,
            size: 46,
            center: circle.isComplete
                ? Icon(Icons.verified, size: 14, color: c.gold)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(circle.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.ink)),
                    ),
                    if (!circle.isCreator) ...[const SizedBox(width: 6), const Tag('منضم', deep: true)],
                  ],
                ),
                if (circle.dedication != null && circle.dedication!.isNotEmpty)
                  Text(circle.dedication!, style: TextStyle(fontSize: 11, color: c.gold)),
                Text(
                  '${arabicNumber(circle.completedCount)} من ٣٠ جزءًا · ${arabicNumber(circle.members.length)} أعضاء',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, size: 18, color: c.faint),
        ],
      ),
    );
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
            const RubElHizb(),
            const SizedBox(height: 14),
            Text('حلقات الختمة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: c.ink)),
            const SizedBox(height: 8),
            Text(
              'اقسموا ختمة القرآن بينكم — للأسرة، للأصدقاء،\nأو صدقةً عن روحٍ غالية — وتُذهَّب شمستُكم معًا',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.muted, height: 1.7),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoldPill(label: 'أنشئ حلقة', onTap: () => showWrdSheet(context, const CreateCircleSheet())),
                const SizedBox(width: 10),
                GoldPill(
                  label: 'انضمّ برمز',
                  filled: false,
                  onTap: () => showWrdSheet(context, const JoinCircleSheet(), tall: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Join / paste a code

class JoinCircleSheet extends StatefulWidget {
  const JoinCircleSheet({super.key});

  @override
  State<JoinCircleSheet> createState() => _JoinCircleSheetState();
}

class _JoinCircleSheetState extends State<JoinCircleSheet> {
  final _pasted = TextEditingController();

  @override
  void dispose() {
    _pasted.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final store = StoreScope.read(context);
    final String message;
    switch (CircleCodec.read(_pasted.text)) {
      case OutcomeDecoded(:final decoded):
        message = store.merge(decoded);
        Haptics.success();
      case OutcomeExpired():
        message = 'انتهت صلاحية هذه الدعوة — اطلب من صاحب الحلقة دعوةً جديدة';
      case OutcomeNotFound():
        message = 'لم أجد رمزًا صالحًا في النص — تأكد من لصق الرسالة كاملة';
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تمّ'))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('انضمّ برمز', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إغلاق', style: TextStyle(color: c.muted)),
        ),
        leadingWidth: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('ألصِق رسالة الدعوة أو رمز التقدم كما وصلتك — وِرْد يجد الرمز بنفسه.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.muted)),
            const SizedBox(height: 14),
            Wash(
              cornerRadius: 16,
              padding: const EdgeInsets.all(14),
              child: WrdField(
                placeholder: 'ألصِق هنا…',
                controller: _pasted,
                multiline: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            GoldPill(label: 'استيراد', expand: true, onTap: _pasted.text.trim().isEmpty ? null : _import),
          ],
        ),
      ),
    );
  }
}

// MARK: - Circle detail

class CircleDetailScreen extends StatelessWidget {
  final String circleId;
  const CircleDetailScreen({super.key, required this.circleId});

  Future<void> _whoAmI(BuildContext context, WrdStore store, KhatmaCircle circle) async {
    final member = await choose<KhatmaMember>(
      context,
      title: 'من أنت في هذه الحلقة؟',
      options: [for (final m in circle.members) (m.name, m)],
    );
    if (member == null) return;
    final updated = circle.copy()..myMemberId = member.id;
    store.updateCircle(updated);
    Haptics.medium();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final circle = store.circleById(circleId);
    if (circle == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        title: Text(circle.name, style: const TextStyle(fontSize: 18)),
        actions: [
          if (circle.isCreator)
            IconButton(
              icon: Icon(Icons.qr_code_2, color: c.gold),
              onPressed: () => showWrdSheet(context, InviteQRSheet(circle: circle)),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: c.muted),
            onSelected: (value) async {
              if (value == 'delete') {
                final ok = await confirm(
                  context,
                  title: 'حذف الحلقة؟',
                  message: 'تُحذف الحلقة من جهازك فقط.',
                  confirmLabel: 'احذف',
                  destructive: true,
                );
                if (ok && context.mounted) {
                  store.removeCircle(circle);
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('حذف الحلقة')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: circle.isComplete
                        ? [BoxShadow(color: c.gold.withValues(alpha: 0.5), blurRadius: 20)]
                        : null,
                  ),
                  child: GateRing(
                    progress: circle.progress,
                    size: 110,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(arabicNumber(circle.completedCount),
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: c.gold)),
                        Text('من ٣٠', style: TextStyle(fontSize: 11, color: c.muted)),
                      ],
                    ),
                  ),
                ),
                if (circle.dedication != null && circle.dedication!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(circle.dedication!, style: TextStyle(fontSize: 14, color: c.gold)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (circle.isComplete) ...[
            Wash(
              gold: true,
              cornerRadius: 16,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.verified, color: c.gold, size: 20),
                  const SizedBox(width: 10),
                  Text('اكتملت الختمة — تقبّل الله منكم',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.gold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!circle.isCreator && circle.myMemberId == null) ...[
            Wash(
              gold: true,
              cornerRadius: 16,
              padding: const EdgeInsets.all(14),
              onTap: () => _whoAmI(context, store, circle),
              child: Row(
                children: [
                  Icon(Icons.person_search_outlined, color: c.gold, size: 20),
                  const SizedBox(width: 10),
                  Text('حدّد اسمك لتتمكن من تعليم أجزائك',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.gold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (final member in circle.members) ...[
            _MemberCard(circle: circle, member: member),
            const SizedBox(height: 12),
          ],
          Text(
            circle.isCreator
                ? 'شارك الدعوة من الأعلى — وعندما يرسل الإخوة رموز تقدمهم ألصِقها من «انضمّ برمز»'
                : 'انقر أجزاءك أنت فقط — ثم شارك رمز تقدمك في المجموعة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: c.faint),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final KhatmaCircle circle;
  final KhatmaMember member;
  const _MemberCard({required this.circle, required this.member});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final editable = circle.canEdit(member);
    final isMe = member.id == circle.myMemberId;

    return Opacity(
      opacity: editable ? 1 : 0.75,
      child: Wash(
        cornerRadius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(member.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.ink)),
                if (isMe) ...[const SizedBox(width: 6), const Tag('أنت')],
                const Spacer(),
                Text('${arabicNumber(member.completed.length)} من ${arabicNumber(member.assigned.length)}',
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final juz in member.assigned)
                  _JuzChip(
                    juz: juz,
                    done: member.completed.contains(juz),
                    onTap: () {
                      if (!editable) {
                        Haptics.light();
                        return;
                      }
                      final updated = circle.copy();
                      final target = updated.members.firstWhere((m) => m.id == member.id);
                      if (target.completed.contains(juz)) {
                        target.completed.remove(juz);
                      } else {
                        target.completed.add(juz);
                        Haptics.success();
                      }
                      store.updateCircle(updated);
                    },
                  ),
              ],
            ),
            if (isMe && member.completed.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Share.share(CircleCodec.progressMessage(circle, member)),
                child: Row(
                  children: [
                    Icon(Icons.send_outlined, size: 16, color: c.gold),
                    const SizedBox(width: 6),
                    Text('شارك تقدمي في المجموعة',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.gold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JuzChip extends StatelessWidget {
  final int juz;
  final bool done;
  final VoidCallback onTap;
  const _JuzChip({required this.juz, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? c.gold : c.washStrong,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(arabicNumber(juz),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: done ? c.ground : c.muted)),
      ),
    );
  }
}

// MARK: - Invitation as a QR code

class InviteQRSheet extends StatelessWidget {
  final KhatmaCircle circle;
  const InviteQRSheet({super.key, required this.circle});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final code = CircleCodec.inviteCode(circle);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعوة', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إغلاق', style: TextStyle(color: c.muted)),
        ),
        leadingWidth: 80,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('دعوة «${circle.name}»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: c.ink)),
          const SizedBox(height: 18),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 240,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('يمسحه الضيف بكاميرا الهاتف العادية → «نسخ»\nثم في وِرْد: الحلقات → «انضمّ برمز» → لصق',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.muted, height: 1.7)),
          const SizedBox(height: 18),
          GoldPill(
            label: 'أرسل الدعوة نصًا (واتساب)',
            icon: Icons.chat_bubble_outline,
            expand: true,
            onTap: () => Share.share(CircleCodec.inviteMessage(circle)),
          ),
          const SizedBox(height: 10),
          GoldPill(
            label: 'انسخ الرمز',
            icon: Icons.copy_outlined,
            filled: false,
            expand: true,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('نُسخ رمز الدعوة')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'الدعوة صالحة ثلاثة أيام، ولا يمكن إضافتها مرتين على الجهاز نفسه. الدعوة التي تُستهلك مرةً واحدة فقط للجميع قادمة مع المزامنة بإذن الله.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.faint),
          ),
        ],
      ),
    );
  }
}

// MARK: - Create circle — the creator controls the split

class CreateCircleSheet extends StatefulWidget {
  const CreateCircleSheet({super.key});

  @override
  State<CreateCircleSheet> createState() => _CreateCircleSheetState();
}

class _CreateCircleSheetState extends State<CreateCircleSheet> {
  final _name = TextEditingController();
  final _dedication = TextEditingController();
  final List<TextEditingController> _memberNames = [TextEditingController(), TextEditingController()];
  final List<int> _memberCounts = [15, 15];

  @override
  void dispose() {
    _name.dispose();
    _dedication.dispose();
    for (final m in _memberNames) {
      m.dispose();
    }
    super.dispose();
  }

  List<(String, int)> get _validPairs {
    final pairs = <(String, int)>[];
    for (var i = 0; i < _memberNames.length; i++) {
      final name = _memberNames[i].text.trim();
      if (name.isNotEmpty) pairs.add((name, _memberCounts[i]));
    }
    return pairs;
  }

  int get _total => _validPairs.fold(0, (sum, p) => sum + p.$2);
  bool get _canSave => _name.text.trim().isNotEmpty && _validPairs.isNotEmpty && _total == 30;

  void _rebalance() {
    final named = <int>[];
    for (var i = 0; i < _memberNames.length; i++) {
      if (_memberNames[i].text.trim().isNotEmpty) named.add(i);
    }
    final targets = named.isEmpty ? List.generate(_memberNames.length, (i) => i) : named;
    final counts = WrdStore.evenCounts(targets.length);
    setState(() {
      for (var i = 0; i < _memberCounts.length; i++) {
        _memberCounts[i] = 0;
      }
      for (var k = 0; k < targets.length; k++) {
        _memberCounts[targets[k]] = counts[k];
      }
    });
  }

  void _create() {
    final store = StoreScope.read(context);
    final pairs = _validPairs;
    final members = WrdStore.allocateAjza(pairs.map((p) => p.$1).toList(), pairs.map((p) => p.$2).toList());
    if (members.isEmpty) return;
    final dedication = _dedication.text.trim();
    store.addCircle(KhatmaCircle(
      name: _name.text.trim(),
      dedication: dedication.isEmpty ? null : dedication,
      members: members,
    ));
    Haptics.success();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('حلقة جديدة', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: TextStyle(color: c.muted)),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _canSave ? _create : null,
            child: Text('إنشاء',
                style: TextStyle(color: _canSave ? c.gold : c.faint, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SectionLabel('الحلقة'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: WrdField(
                    placeholder: 'اسم الحلقة — مثال: ختمة العائلة',
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: WrdField(placeholder: 'النية أو الإهداء (اختياري)', controller: _dedication),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('الأعضاء وقسمة الأجزاء'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < _memberNames.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: WrdField(
                            placeholder: 'اسم العضو',
                            controller: _memberNames[i],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        WashIconButton(
                          icon: Icons.remove,
                          size: 28,
                          onTap: () => setState(() => _memberCounts[i] = (_memberCounts[i] - 1).clamp(0, 30).toInt()),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(arabicNumber(_memberCounts[i]),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.gold)),
                        ),
                        WashIconButton(
                          icon: Icons.add,
                          size: 28,
                          onTap: () => setState(() => _memberCounts[i] = (_memberCounts[i] + 1).clamp(0, 30).toInt()),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _memberNames.add(TextEditingController());
                      _memberCounts.add(0);
                    });
                    _rebalance();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18, color: c.gold),
                        const SizedBox(width: 8),
                        Text('أضِف عضوًا', style: TextStyle(fontSize: 15, color: c.gold)),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text('المجموع', style: TextStyle(fontSize: 15, color: c.ink)),
                      const Spacer(),
                      Text('${arabicNumber(_total)} من ٣٠',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _total == 30 ? c.gold : Theme.of(context).colorScheme.error,
                          )),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: _rebalance,
                        child: Text('قسّم بالتساوي',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.goldDeep)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'أنت من يقرر كم جزءًا لكل أخٍ وأخت — وتُسنَد الأجزاء بالترتيب (الأول من ١، والذي يليه يكمل…). يجب أن يكون المجموع ٣٠.',
            style: TextStyle(fontSize: 12, color: c.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

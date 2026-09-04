import 'package:flutter/material.dart';

import '../data/adhkar_library.dart';
import '../models/gate.dart';
import '../models/wird.dart';
import '../store/store_scope.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';
import 'compose_screen.dart';
import 'counter_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Wash(
            cornerRadius: 18,
            padding: const EdgeInsets.all(14),
            onTap: () => showWrdSheet(context, const ComposeScreen()),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(13)),
                  child: Icon(Icons.add, color: c.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أنشئ وِردك الخاص',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.gold)),
                      Text('دعاء شخصي، عدد تسبيح، أو نية تحفظها',
                          style: TextStyle(fontSize: 11, color: c.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final category in AdhkarLibrary.all) ...[
            Wash(
              cornerRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryScreen(category: category)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Icon(category.icon, color: c.gold, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.title,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.ink)),
                        Text(category.subtitle, style: TextStyle(fontSize: 11, color: c.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, size: 18, color: c.faint),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text('كل ذكرٍ بمصدره — والمحتوى في مراجعةٍ علمية قبل الإطلاق.',
              style: TextStyle(fontSize: 11, color: c.faint)),
        ],
      ),
    );
  }
}

// MARK: - Category detail

class CategoryScreen extends StatelessWidget {
  final AdhkarCategory category;
  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title, style: const TextStyle(fontSize: 18))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: category.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ItemCard(wird: category.items[i]),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Wird wird;
  const _ItemCard({required this.wird});

  Future<void> _addToGate(BuildContext context) async {
    final store = StoreScope.read(context);
    final gate = await choose<Gate>(
      context,
      title: 'أين تُضيف هذا الوِرد؟',
      options: [for (final g in Gate.values) (g.arabicTitle, g)],
    );
    if (gate == null) return;
    store.addToGate(wird, gate);
    Haptics.medium();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final saved = store.contains(wird);
    return Wash(
      cornerRadius: 18,
      padding: const EdgeInsets.all(16),
      onTap: () => CounterScreen.open(context, wird),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(wird.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.ink)),
              ),
              if (wird.targetCount > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(20)),
                  child: Text('يُكرَّر ×${arabicNumber(wird.targetCount)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.gold)),
                ),
            ],
          ),
          if (wird.text != null) ...[
            const SizedBox(height: 10),
            Text(wird.text!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: c.muted, height: 1.7)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (wird.source != null)
                Expanded(child: Text(wird.source!, style: TextStyle(fontSize: 11, color: c.goldDeep)))
              else
                const Spacer(),
              GestureDetector(
                onTap: () {
                  if (saved) {
                    store.remove(wird);
                  } else {
                    _addToGate(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: saved ? c.wash : c.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(saved ? 'في أورادي ✓' : 'أضِف إلى وِردي',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500, color: saved ? c.muted : c.ground)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

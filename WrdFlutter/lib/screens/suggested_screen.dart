import 'package:flutter/material.dart';

import '../data/adhkar_library.dart';
import '../models/wird.dart';
import '../store/store_scope.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';

/// The suggested set — you choose which of them enters your space.
class SuggestedScreen extends StatefulWidget {
  const SuggestedScreen({super.key});

  @override
  State<SuggestedScreen> createState() => _SuggestedScreenState();
}

class _SuggestedScreenState extends State<SuggestedScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = WrdColors.of(context);
    final suggestions = AdhkarLibrary.starterAwrad.where((w) => !store.contains(w)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأوراد المقترحة', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إغلاق', style: TextStyle(color: c.muted)),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    for (final wird in suggestions) {
                      if (_selected.contains(wird.id)) store.add(wird);
                    }
                    Haptics.medium();
                    Navigator.pop(context);
                  },
            child: Text(
              _selected.isEmpty ? 'أضِف' : 'أضِف ${arabicNumber(_selected.length)}',
              style: TextStyle(color: _selected.isEmpty ? c.faint : c.gold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: suggestions.isEmpty
          ? Center(
              child: Text('كل الأوراد المقترحة عندك بالفعل — ما شاء الله',
                  style: TextStyle(fontSize: 14, color: c.muted)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text('اختر ما يناسبك — ولا شيء يُفرض عليك', style: TextStyle(fontSize: 13, color: c.faint)),
                const SizedBox(height: 10),
                for (final wird in suggestions) ...[
                  _Row(
                    wird: wird,
                    selected: _selected.contains(wird.id),
                    onTap: () {
                      setState(() {
                        if (_selected.contains(wird.id)) {
                          _selected.remove(wird.id);
                        } else {
                          _selected.add(wird.id);
                        }
                      });
                      Haptics.light();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final Wird wird;
  final bool selected;
  final VoidCallback onTap;
  const _Row({required this.wird, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Wash(
      strong: selected,
      cornerRadius: 15,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(selected ? Icons.check_circle : Icons.circle_outlined,
              size: 24, color: selected ? c.gold : c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wird.title, style: TextStyle(fontSize: 16, color: c.ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(wird.gate.arabicTitle, style: TextStyle(fontSize: 12, color: c.goldDeep)),
                    if (wird.source != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(wird.source!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.muted)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (wird.targetCount > 1)
            Text('×${arabicNumber(wird.targetCount)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.gold)),
        ],
      ),
    );
  }
}

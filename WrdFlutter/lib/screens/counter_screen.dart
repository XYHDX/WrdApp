import 'package:flutter/material.dart';

import '../models/gate.dart';
import '../models/wird.dart';
import '../store/store_scope.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';

/// The tasbīḥ counter — tap the big ring area to count. A feather-tap per
/// count, a deeper pulse every 33, and the kindle when the target is reached.
/// Reaching the target marks the wird READ for today in أورادي.
class CounterScreen extends StatefulWidget {
  final Wird wird;
  const CounterScreen({super.key, required this.wird});

  static Future<void> open(BuildContext context, Wird wird) =>
      showWrdSheet(context, CounterScreen(wird: wird));

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;
  bool _kindled = false;

  Wird get wird => widget.wird;
  int get target => wird.targetCount < 1 ? 1 : wird.targetCount;
  double get progress => (_count / target).clamp(0.0, 1.0).toDouble();
  bool get isLongText => (wird.text?.length ?? 0) > 180;

  @override
  void initState() {
    super.initState();
    final store = StoreScope.read(context);
    _count = store.countFor(wird);
    _kindled = _count >= target;
  }

  void _advance() {
    if (_count >= target) return;
    final store = StoreScope.read(context);
    setState(() => _count += 1);
    store.setCount(_count, wird);
    if (_count >= target) {
      Haptics.success();
      setState(() => _kindled = true);
    } else if (_count % 33 == 0) {
      Haptics.medium();
    } else {
      Haptics.light();
    }
  }

  void _reset() {
    final store = StoreScope.read(context);
    setState(() {
      _count = 0;
      _kindled = false;
    });
    store.resetToday(wird);
    Haptics.light();
  }

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final ringSize = isLongText ? 150.0 : 210.0;
    return Container(
      color: c.ground,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Column(
        children: [
          Row(
            children: [
              WashIconButton(icon: Icons.close, onTap: () => Navigator.pop(context)),
              const Spacer(),
              if (wird.gate != Gate.general)
                Text(wird.gate.arabicTitle, style: TextStyle(fontSize: 12, color: c.faint)),
              if (_count > 0) ...[
                const SizedBox(width: 10),
                WashIconButton(icon: Icons.replay, onTap: _reset),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            wird.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.ink),
          ),
          if (wird.source != null) ...[
            const SizedBox(height: 4),
            Text(wird.source!, style: TextStyle(fontSize: 12, color: c.goldDeep)),
          ],
          if (wird.text != null) ...[
            const SizedBox(height: 16),
            Flexible(
              flex: isLongText ? 3 : 2,
              child: Container(
                constraints: BoxConstraints(maxHeight: isLongText ? 420 : 240),
                decoration: BoxDecoration(
                  color: WrdColors.parchmentAlways,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    wird.text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isLongText ? 17 : 21,
                      height: isLongText ? 1.9 : 2.1,
                      color: WrdColors.inkAlways,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _advance,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.wash,
                boxShadow: _kindled
                    ? [BoxShadow(color: c.gold.withValues(alpha: 0.45), blurRadius: 24)]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GateRing(
                  progress: progress,
                  size: ringSize - 20,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        arabicNumber(_count),
                        style: TextStyle(
                          fontSize: isLongText ? 32 : 44,
                          fontWeight: FontWeight.w600,
                          color: _kindled ? c.gold : c.ink,
                        ),
                      ),
                      Text(
                        _kindled ? 'أُضيء' : 'من ${arabicNumber(target)}',
                        style: TextStyle(fontSize: 12, color: _kindled ? c.gold : c.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _kindled ? 'تقبّل الله' : 'انقر الدائرة للعدّ',
            style: TextStyle(fontSize: 13, color: _kindled ? c.gold : c.faint),
          ),
          const SizedBox(height: 16),
          GoldPill(
            label: _kindled ? 'تمّ' : 'رجوع',
            filled: _kindled,
            expand: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/wrd_colors.dart';

/// Haptics — real light in the hand.
class Haptics {
  Haptics._();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
}

/// Soft wash surface — WRD never draws borders; containment is a fill + shadow.
class Wash extends StatelessWidget {
  final Widget child;
  final bool strong;
  final bool gold;
  final double cornerRadius;
  final EdgeInsetsGeometry padding;
  final bool shadow;
  final VoidCallback? onTap;

  const Wash({
    super.key,
    required this.child,
    this.strong = false,
    this.gold = false,
    this.cornerRadius = 22,
    this.padding = EdgeInsets.zero,
    this.shadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final fill = gold ? c.goldWash : (strong ? c.washStrong : c.wash);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

/// The gate progress ring — light being kindled.
class GateRing extends StatelessWidget {
  final double progress;
  final double size;
  final Widget? center;

  const GateRing({super.key, required this.progress, this.size = 64, this.center});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            track: c.goldWash,
            fill: c.gold,
            strokeWidth: size * 0.08,
          ),
          child: Center(
            child: center ??
                Container(
                  width: size * 0.14,
                  height: size * 0.14,
                  decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle),
                ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color fill;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(inset, 0, 2 * math.pi, false, trackPaint);
    if (progress <= 0) return;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(inset, -math.pi / 2, 2 * math.pi * progress, false, fillPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

/// Arabic-first text field. The platform placeholder follows the DEVICE
/// language (left-aligned on English phones), so WRD draws its own — it
/// always sits where Arabic begins, whatever the phone's language.
class WrdField extends StatelessWidget {
  final String placeholder;
  final TextEditingController controller;
  final bool multiline;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;

  const WrdField({
    super.key,
    required this.placeholder,
    required this.controller,
    this.multiline = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final textStyle = style ?? Theme.of(context).textTheme.bodyLarge;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType ?? (multiline ? TextInputType.multiline : TextInputType.text),
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 8 : 1,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      style: textStyle,
      cursorColor: c.gold,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: textStyle?.copyWith(color: c.faint),
        hintTextDirection: TextDirection.rtl,
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.goldDeep),
    );
  }
}

/// Primary pill — gold, ink on gold. `filled: false` gives the gold-wash variant.
class GoldPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool expand;

  const GoldPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.filled = true,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    final enabled = onTap != null;
    final fg = filled ? c.ground : c.gold;
    final bg = filled ? (enabled ? c.gold : c.goldDeep.withValues(alpha: 0.4)) : c.goldWash;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round wash button (close, undo, trash…).
class WashIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  const WashIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.wash, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.5, color: color ?? c.muted),
      ),
    );
  }
}

/// Tiny capsule tag — "خاص", "أنت", "منضم".
class Tag extends StatelessWidget {
  final String text;
  final bool deep;
  const Tag(this.text, {super.key, this.deep = false});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: deep ? c.goldDeep : c.gold),
      ),
    );
  }
}

/// The ۞ mark used as the empty-state ornament.
class RubElHizb extends StatelessWidget {
  final double size;
  const RubElHizb({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Text('۞', style: TextStyle(fontSize: size, color: WrdColors.of(context).gold));
  }
}

/// Opens a WRD-styled bottom sheet that fills most of the screen.
Future<T?> showWrdSheet<T>(BuildContext context, Widget child, {bool tall = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(heightFactor: tall ? 0.94 : 0.6, child: child),
  );
}

/// Simple confirm dialog. Returns true when confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool destructive = false,
}) async {
  final c = WrdColors.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: TextStyle(color: c.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel, style: TextStyle(color: c.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? Theme.of(ctx).colorScheme.error : c.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A gate/option chooser presented as a list of choices.
Future<T?> choose<T>(BuildContext context, {required String title, required List<(String, T)> options}) {
  final c = WrdColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
            ),
            for (final (label, value) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wash(
                  cornerRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: () => Navigator.pop(ctx, value),
                  child: Center(
                    child: Text(label, style: TextStyle(fontSize: 16, color: c.gold, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

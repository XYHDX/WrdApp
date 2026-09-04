import 'package:flutter/material.dart';

/// WRD color system — parchment by day, candlelight by night.
/// Rules: gold is earned; no borders anywhere; never blue-black, never pure
/// black, never cold blues.
class WrdColors {
  final bool dark;
  const WrdColors._(this.dark);

  static WrdColors of(BuildContext context) =>
      WrdColors._(Theme.of(context).brightness == Brightness.dark);

  static const parchment = WrdColors._(false);
  static const candlelight = WrdColors._(true);

  // Grounds
  Color get ground => dark ? const Color(0xFF1D1710) : const Color(0xFFF7F1E2);
  Color get groundHigh => dark ? const Color(0xFF241C12) : const Color(0xFFFFFDF6);

  // Content
  Color get ink => dark ? const Color(0xFFF0E6D2) : const Color(0xFF2B2118);
  Color get muted => dark ? const Color(0xFFA79878) : const Color(0xFF7A6E55);
  Color get faint => dark ? const Color(0xFF5E5850) : const Color(0xFFB0A488);

  // Gold — marks completed worship and primary actions only
  Color get gold => dark ? const Color(0xFFD6B25E) : const Color(0xFF8E6D1F);
  Color get goldDeep => dark ? const Color(0xFFB08D36) : const Color(0xFF6E5416);

  // Washes — containment is a soft fill + shadow, never an outline
  Color get wash => const Color(0xFF54401F).withValues(alpha: dark ? 0.26 : 0.06);
  Color get washStrong => const Color(0xFF54401F).withValues(alpha: dark ? 0.40 : 0.10);
  Color get goldWash => gold.withValues(alpha: dark ? 0.12 : 0.10);

  // The mushaf is parchment in BOTH themes — ink on paper is the tradition
  static const Color parchmentAlways = Color(0xFFF7F1E2);
  static const Color inkAlways = Color(0xFF2B2118);
}

import 'package:flutter/material.dart';

import 'wrd_colors.dart';

/// Material themes carrying the WRD palette. No outlines anywhere; type does
/// the structuring. The fonts are the platform's Arabic system faces
/// (SF Arabic on iOS, Noto Naskh Arabic on Android) — Amiri can be bundled
/// later under assets/fonts and set as `fontFamily`.
ThemeData wrdTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? WrdColors.candlelight : WrdColors.parchment;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.gold,
    onPrimary: c.ground,
    secondary: c.goldDeep,
    onSecondary: c.ground,
    error: const Color(0xFFB4533A),
    onError: Colors.white,
    surface: c.ground,
    onSurface: c.ink,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.ground,
    splashFactory: NoSplash.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: c.ground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: c.ink,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.groundHigh,
      selectedItemColor: c.gold,
      unselectedItemColor: c.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: c.wash, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.ground : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.gold : c.washStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    listTileTheme: ListTileThemeData(iconColor: c.gold, textColor: c.ink),
    dialogTheme: DialogThemeData(
      backgroundColor: c.groundHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.ground,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.faint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.gold),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.gold),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.groundHigh,
      contentTextStyle: TextStyle(color: c.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

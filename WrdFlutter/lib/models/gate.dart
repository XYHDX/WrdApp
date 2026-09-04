import 'package:flutter/material.dart';

/// The four gates of WRD — التوقيتات.
enum Gate {
  morning,
  afterPrayer,
  night,
  general;

  String get arabicTitle {
    switch (this) {
      case Gate.morning:
        return 'الوِرد الصباحي';
      case Gate.afterPrayer:
        return 'أوراد ما بعد الصلاة';
      case Gate.night:
        return 'الوِرد الليلي';
      case Gate.general:
        return 'أوراد الأحوال';
    }
  }

  String get subtitle {
    switch (this) {
      case Gate.morning:
        return 'بعد الفجر حتى الشروق';
      case Gate.afterPrayer:
        return 'بعد كل صلاة';
      case Gate.night:
        return 'المساء وقبل النوم';
      case Gate.general:
        return 'أذكار المواقف اليومية';
    }
  }

  IconData get icon {
    switch (this) {
      case Gate.morning:
        return Icons.wb_twilight_outlined;
      case Gate.afterPrayer:
        return Icons.volunteer_activism_outlined;
      case Gate.night:
        return Icons.nightlight_outlined;
      case Gate.general:
        return Icons.auto_awesome_outlined;
    }
  }

  /// Wire value — identical to the Swift raw values so JSON carries over.
  String get wire => name;

  static Gate fromWire(String? value) {
    for (final gate in Gate.values) {
      if (gate.name == value) return gate;
    }
    return Gate.general;
  }
}

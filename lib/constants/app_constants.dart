import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'EcoSignal MD';
  static const String appVersion = '1.0.0';
  static const int pageSize = 20;
  static const Duration searchDebounce = Duration(milliseconds: 500);

  static const String dataSourceName = 'Maryland Department of the Environment';
  static const String dataSourceUrl =
      'https://opendata.maryland.gov/d/hxmu-urvx';

  static const String privacyPolicyUrl =
      'https://ecosignal-a10ae.web.app/privacy.html';
  static const String termsOfServiceUrl =
      'https://ecosignal-a10ae.web.app/terms.html';

  static const List<String> scopedCounties = [
    'Allegany',
    'Anne Arundel',
    'Baltimore',
    'Baltimore City',
    'Calvert',
    'Caroline',
    'Carroll',
    'Cecil',
    'Charles',
    'Dorchester',
    'Frederick',
    'Garrett',
    'Harford',
    'Howard',
    'Kent',
    'Montgomery',
    "Prince George's",
    "Queen Anne's",
    "St. Mary's",
    'Somerset',
    'Talbot',
    'Washington',
    'Wicomico',
    'Worcester',
  ];

  AppConstants._();
}

enum TextScaleOption {
  small,
  medium,
  large;

  double get scaleFactor {
    switch (this) {
      case TextScaleOption.small:
        return 0.85;
      case TextScaleOption.medium:
        return 1.0;
      case TextScaleOption.large:
        return 1.2;
    }
  }

  String get label {
    switch (this) {
      case TextScaleOption.small:
        return 'Small';
      case TextScaleOption.medium:
        return 'Medium';
      case TextScaleOption.large:
        return 'Large';
    }
  }

  String get dbValue => name;

  static TextScaleOption fromDb(String? value) => TextScaleOption.values
      .firstWhere((e) => e.name == value, orElse: () => TextScaleOption.medium);
}

enum ColorThemeOption {
  forest,
  ocean,
  sky,
  amber,
  berry,
  coral;

  String get label {
    switch (this) {
      case ColorThemeOption.forest:
        return 'Forest';
      case ColorThemeOption.ocean:
        return 'Ocean';
      case ColorThemeOption.sky:
        return 'Sky';
      case ColorThemeOption.amber:
        return 'Amber';
      case ColorThemeOption.berry:
        return 'Berry';
      case ColorThemeOption.coral:
        return 'Coral';
    }
  }

  Color get primary {
    switch (this) {
      case ColorThemeOption.forest:
        return const Color(0xFF1E8E3E);
      case ColorThemeOption.ocean:
        return const Color(0xFF0B7A99);
      case ColorThemeOption.sky:
        return const Color(0xFF2196D9);
      case ColorThemeOption.amber:
        return const Color(0xFFC9781E);
      case ColorThemeOption.berry:
        return const Color(0xFF7A4FC9);
      case ColorThemeOption.coral:
        return const Color(0xFFD9503F);
    }
  }

  Color get secondary {
    switch (this) {
      case ColorThemeOption.forest:
        return const Color(0xFF5AB72E);
      case ColorThemeOption.ocean:
        return const Color(0xFF17BCCF);
      case ColorThemeOption.sky:
        return const Color(0xFF6EC6FF);
      case ColorThemeOption.amber:
        return const Color(0xFFF2B705);
      case ColorThemeOption.berry:
        return const Color(0xFFB47FE0);
      case ColorThemeOption.coral:
        return const Color(0xFFF08A6C);
    }
  }

  String get dbValue => name;

  static ColorThemeOption fromDb(String? value) =>
      ColorThemeOption.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ColorThemeOption.forest,
      );
}

enum ReportCategory {
  erosion,
  flooding,
  waterPollution,
  illegalDumping,
  habitatDamage,
  other;

  String get label {
    switch (this) {
      case ReportCategory.erosion:
        return 'Erosion';
      case ReportCategory.flooding:
        return 'Flooding';
      case ReportCategory.waterPollution:
        return 'Water Pollution';
      case ReportCategory.illegalDumping:
        return 'Illegal Dumping';
      case ReportCategory.habitatDamage:
        return 'Habitat Damage';
      case ReportCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.erosion:
        return Icons.terrain_rounded;
      case ReportCategory.flooding:
        return Icons.water_rounded;
      case ReportCategory.waterPollution:
        return Icons.opacity_rounded;
      case ReportCategory.illegalDumping:
        return Icons.delete_outline_rounded;
      case ReportCategory.habitatDamage:
        return Icons.eco_outlined;
      case ReportCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String get responsibleAgency {
    switch (this) {
      case ReportCategory.erosion:
      case ReportCategory.waterPollution:
        return 'Maryland Department of the Environment (MDE)';
      case ReportCategory.habitatDamage:
        return 'Maryland Department of Natural Resources (DNR)';
      case ReportCategory.flooding:
        return 'Your county or local government';
      case ReportCategory.illegalDumping:
        return "MDE, or your county's illegal-dumping hotline";
      case ReportCategory.other:
        return 'Ask EcoGuide — it can help point you to the right place';
    }
  }

  String get dbValue => name;

  static ReportCategory fromDb(String? value) => ReportCategory.values
      .firstWhere((e) => e.name == value, orElse: () => ReportCategory.other);
}

enum ReportStatus {
  active,
  removed;

  String get dbValue => name;

  static ReportStatus fromDb(String? value) => ReportStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ReportStatus.active,
  );
}

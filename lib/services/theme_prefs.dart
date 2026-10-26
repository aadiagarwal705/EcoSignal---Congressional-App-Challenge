import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

typedef AppSettings = ({
  ThemeMode theme,
  TextScaleOption textScale,
  ColorThemeOption colorTheme,
});

class ThemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _themeKey = 'settings.theme';
  static const _textScaleKey = 'settings.text_scale';
  static const _colorThemeKey = 'settings.color_theme';

  static const AppSettings defaults = (
    theme: ThemeMode.system,
    textScale: TextScaleOption.medium,
    colorTheme: ColorThemeOption.forest,
  );

  static String _themeToDb(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
  };

  static ThemeMode _themeFromDb(String? value) => switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  Future<void> _save(String localKey, String value, String remoteField) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(localKey, value);
    } catch (_) {}

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('user_preferences').doc(uid).set({
        remoteField: value,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) =>
      _save(_themeKey, _themeToDb(mode), 'theme');

  Future<void> setTextScale(TextScaleOption option) =>
      _save(_textScaleKey, option.dbValue, 'text_scale');

  Future<void> setColorTheme(ColorThemeOption option) =>
      _save(_colorThemeKey, option.dbValue, 'color_theme');

  Future<AppSettings> loadAll() async {
    var settings = defaults;

    try {
      final prefs = await SharedPreferences.getInstance();
      settings = (
        theme: _themeFromDb(prefs.getString(_themeKey)),
        textScale: TextScaleOption.fromDb(prefs.getString(_textScaleKey)),
        colorTheme: ColorThemeOption.fromDb(prefs.getString(_colorThemeKey)),
      );
    } catch (_) {}

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return settings;
    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return settings;
      return (
        theme: data['theme'] != null
            ? _themeFromDb(data['theme'] as String?)
            : settings.theme,
        textScale: data['text_scale'] != null
            ? TextScaleOption.fromDb(data['text_scale'] as String?)
            : settings.textScale,
        colorTheme: data['color_theme'] != null
            ? ColorThemeOption.fromDb(data['color_theme'] as String?)
            : settings.colorTheme,
      );
    } catch (_) {
      return settings;
    }
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

enum AppThemeMode {
  system,
  dark,
  colorblind,
}

// ─── Provider ────────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ─── Notifier ────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'feira_facil_theme_mode';

  ThemeModeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = kIsWeb ? _webRead() : await _nativeRead();
      if (saved == 'dark') {
        state = AppThemeMode.dark;
      } else if (saved == 'colorblind') {
        state = AppThemeMode.colorblind;
      } else {
        state = AppThemeMode.system;
      }
    } catch (_) {
      state = AppThemeMode.system;
    }
  }

  // ── Web: localStorage direto ────────────────────────────────────────────────
  String? _webRead() {
    try {
      return html.window.localStorage[_key];
    } catch (_) {
      return null;
    }
  }

  void _webWrite(String value) {
    try {
      html.window.localStorage[_key] = value;
    } catch (_) {}
  }

  // ── Native: SharedPreferences ───────────────────────────────────────────────
  Future<String?> _nativeRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> _nativeWrite(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  // ── Public API ──────────────────────────────────────────────────────────────
  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      AppThemeMode.dark       => 'dark',
      AppThemeMode.colorblind => 'colorblind',
      AppThemeMode.system     => 'system',
    };
    try {
      if (kIsWeb) {
        _webWrite(value);
      } else {
        await _nativeWrite(value);
      }
    } catch (_) {}
  }

  void toggle() {
    setMode(state == AppThemeMode.dark ? AppThemeMode.system : AppThemeMode.dark);
  }
}

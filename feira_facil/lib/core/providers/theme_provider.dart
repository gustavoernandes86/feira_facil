import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ─── Provider ────────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ─── Notifier ────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'feira_facil_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = kIsWeb ? _webRead() : await _nativeRead();
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {
      state = ThemeMode.system;
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
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
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
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

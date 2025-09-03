// lib/services/settings/print_date_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

class PrintDatePrefs {
  static const _kEnabled = 'printdate_enabled';
  static const _kIso     = '2025-08-27T19:30:00'; // e.g. 2025-08-27T19:30:00

  static Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kEnabled) ?? false;
    }

  static Future<void> setEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kEnabled, v);
  }

  static Future<DateTime?> getOverride() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kIso);
    if (s == null || s.isEmpty) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  static Future<void> setOverride(DateTime dt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kIso, dt.toIso8601String());
  }

  static Future<void> clearOverride() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kIso);
  }
}

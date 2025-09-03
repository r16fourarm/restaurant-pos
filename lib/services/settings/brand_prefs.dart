// lib/services/settings/brand_prefs.dart
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class BrandPrefs {
  static const _kName = 'brand_name';
  static const _kAddr = 'brand_addr';
  static const _kPhone = 'brand_phone';
  static const _kLogoAsset = 'brand_logo_asset';
  static const _kLogoFile  = 'brand_logo_file';

  /// Change to your bundled default asset (also register in pubspec.yaml)
  static const String defaultAsset = 'assets/logo_bw.png';

  /// Ensure defaults exist (call this early, e.g. in main())
  static Future<void> ensureDefaults() async {
    final sp = await SharedPreferences.getInstance();
    sp.setString(_kName,  sp.getString(_kName)  ?? 'My Cafe');
    sp.setString(_kAddr,  sp.getString(_kAddr)  ?? '');
    sp.setString(_kPhone, sp.getString(_kPhone) ?? '');
    // store a default asset for logo fallback
    sp.setString(_kLogoAsset, sp.getString(_kLogoAsset) ?? defaultAsset);
    // leave _kLogoFile unset until user picks a file
  }

  /// Get current brand settings.
  /// - `logoAsset` is never null (falls back to defaultAsset)
  /// - Prefer `logoFile` (if not null/empty) when building PrinterBrand
  static Future<({
    String name,
    String address,
    String phone,
    String logoAsset,   // never null
    String? logoFile,
  })> getBrand() async {
    final sp = await SharedPreferences.getInstance();
    return (
      name: sp.getString(_kName) ?? 'My Cafe',
      address: sp.getString(_kAddr) ?? '',
      phone: sp.getString(_kPhone) ?? '',
      logoAsset: sp.getString(_kLogoAsset) ?? defaultAsset,
      logoFile: sp.getString(_kLogoFile),
    );
  }

  /// Update brand text fields (name/address/phone).
  static Future<void> setBrand({
    required String name,
    String? address,
    String? phone,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, name);
    if (address != null) await sp.setString(_kAddr, address);
    if (phone != null) await sp.setString(_kPhone, phone);
  }

  /// Set logo from a picked file path.
  /// Copies the file into the app documents dir and stores its path.
  /// Returns the saved path or null if it failed.
  static Future<String?> setLogoFromFile(String pickedPath) async {
    try {
      final src = File(pickedPath);
      if (!await src.exists()) return null;

      final dir = await getApplicationDocumentsDirectory();
      final ext = pickedPath.split('.').last.toLowerCase();
      final dst = File('${dir.path}/receipt_logo.$ext');

      if (await dst.exists()) await dst.delete();
      await src.copy(dst.path);

      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kLogoFile, dst.path); // prefer file when present
      // keep _kLogoAsset as recorded fallback
      return dst.path;
    } catch (_) {
      return null;
    }
  }

  /// Clear file override and revert to default asset.
  static Future<void> resetLogoToAsset() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kLogoFile);
    await sp.setString(_kLogoAsset, defaultAsset);
  }
}

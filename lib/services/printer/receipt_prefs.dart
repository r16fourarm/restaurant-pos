import 'package:shared_preferences/shared_preferences.dart';
import 'print_receipt.dart';

class ReceiptPrefs {
  static const _k = 'receipt_style_v1';
  static Future<void> set(ReceiptStyle s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, s.name);
  }
  static Future<ReceiptStyle> get() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_k);
    return ReceiptStyle.values.firstWhere(
      (e) => e.name == v, orElse: () => ReceiptStyle.standard);
  }
}

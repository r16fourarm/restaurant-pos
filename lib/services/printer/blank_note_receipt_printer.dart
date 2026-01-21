// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:intl/intl.dart';
// import 'print_receipt.dart';

// /// Ultra-minimal, text-only receipt:
// /// - No brand/store/bill info
// /// - Prints: DATE (big), ITEMS, SUBTOTAL, TOTAL (big)
// class BlankNoteReceiptPrinter {
//   final BlueThermalPrinter _printer;
//   final int width; // chars per line for 58mm: ~32 (adjust if needed)

//   BlankNoteReceiptPrinter(this._printer, {this.width = 32});

//   String _money(num v) =>
//       NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
//           .format(v);

//   String _line([String ch = '-']) => ch * width;

//   String _center(String s) {
//     if (s.length >= width) return s.substring(0, width);
//     final pad = (width - s.length) ~/ 2;
//     return ' ' * pad + s;
//     }

//   String _lr(String left, String right) {
//     final l = left.length, r = right.length;
//     if (l + r >= width) return '$left\n${' ' * (width - r)}$right';
//     return '$left${' ' * (width - l - r)}$right';
//   }

//   List<String> _wrap(String text) {
//     final words = text.split(RegExp(r'\s+'));
//     final lines = <String>[];
//     var cur = '';
//     for (final w in words) {
//       final addLen = (cur.isEmpty ? 0 : 1) + w.length;
//       if (cur.length + addLen <= width) {
//         cur = cur.isEmpty ? w : '$cur $w';
//       } else {
//         if (cur.isNotEmpty) lines.add(cur);
//         cur = w;
//       }
//     }
//     if (cur.isNotEmpty) lines.add(cur);
//     return lines;
//   }

//   Future<void> printReceipt(ReceiptData d) async {
//     // === DATE (emphasized) ===
//     final dateStr = DateFormat('dd MMM yyyy  HH:mm').format(d.time);
//     await _printer.printCustom(_center(dateStr), 2, 1); // big & centered
//     await _printer.printCustom(_line('='), 0, 1);

//     // === ITEMS ===
//     for (final it in d.items) {
//       // name
//       for (final line in _wrap(it.name)) {
//         await _printer.printCustom(line, 0, 0);
//       }
//       // qty x price .... lineTotal
//       final qtyPrice = '${it.qty} x ${_money(it.price)}';
//       await _printer.printCustom(_lr(qtyPrice, _money(it.lineTotal)), 0, 0);

//       // optional: addons (still minimal; remove if you want *only* product)
//       for (final a in it.addons) {
//         for (final w in _wrap('• $a')) {
//           await _printer.printCustom(w, 0, 0);
//         }
//       }
//       await _printer.printCustom('', 0, 0); // spacer
//     }

//     await _printer.printCustom(_line('-'), 0, 1);

//     // === TOTALS (subtotal normal, TOTAL big) ===
//     await _printer.printCustom(_lr('Subtotal', _money(d.subtotal)), 0, 0);
//     await _printer.printCustom(_lr('TOTAL', _money(d.grandTotal)), 2, 0); // big

//     // feed
//     await _printer.printNewLine();
//     await _printer.printNewLine();
//   }
// }

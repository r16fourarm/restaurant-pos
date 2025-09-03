import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'receipt_printer.dart';
import 'printer_facade.dart'; // for PrinterBrand

/// Which layout to print
enum ReceiptMode { finalPaid, unpaid }

/// Unified function for both final (paid) receipts and unpaid tickets.
/// - Use `mode: ReceiptMode.finalPaid` when payment is made.
/// - Use `mode: ReceiptMode.unpaid` for pre-payment tickets.
Future<void> printRestaurantReceipt(
  ReceiptPrinter printer, {
  ReceiptMode mode = ReceiptMode.finalPaid,

  // Branding (with logo handled outside in facade)
  required PrinterBrand brand,

  // Meta
  required String billNumber,
  String? table,
  required String cashierOrOrderer,

  // Line items
  required List<Map<String, dynamic>> items, // [{name, qty, total, addons?[]}]
  required double subtotal,
  double tax = 0,
  double service = 0,
  required double total,

  // For final (paid) receipts
  double? paid,
  double? change,

  // Time + footer
  DateTime? time,
  String? footerNote,

  // If logo bytes are available (passed from facade)
  Uint8List? logoBytes,
}) async {
  final now = time ?? DateTime.now();
  final money = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // ===== HEADER =====
  if (logoBytes != null) {
    await printer.printImage(logoBytes, align: AlignX.center);
    await printer.newline();
  }

  await printer.println(brand.name.toUpperCase(), size: 2, align: 1);

  if ((brand.address ?? '').trim().isNotEmpty) {
    await printer.println(brand.address!.trim(), align: 1);
  }
  if ((brand.phone ?? '').trim().isNotEmpty) {
    await printer.println('Tel: ${brand.phone!.trim()}', align: 1);
  }

  await printer.newline();

  // ===== META INFO =====
  await printer.leftRight('Bill No.', billNumber);
  await printer.leftRight('Date', DateFormat('dd/MM/yyyy HH:mm').format(now));
  if ((table ?? '').trim().isNotEmpty) {
    await printer.leftRight('Table', table!.trim());
  }
  await printer.leftRight(
    mode == ReceiptMode.finalPaid ? 'Order By' : 'Order By',
    cashierOrOrderer,
  );

  await printer.divider();

  // ===== ITEMS =====
  for (final it in items) {
    final name = '${it['name']}';
    final qty = (it['qty'] ?? 1).toString();
    final lineTotal = (it['total'] ?? 0) as num;

    // Item line
    await printer.println('$qty x $name');
    await printer.leftRight('', money.format(lineTotal));

    // Add-ons
    final addons = it['addons'];
    if (addons is List) {
      for (final a in addons) {
        final n = (a is Map) ? (a['name'] ?? a.toString()) : a.toString();
        if ((n ?? '').toString().trim().isNotEmpty) {
          await printer.println('  + $n');
        }
      }
    }
  }

  await printer.divider();

  // ===== TOTALS =====
  if (mode == ReceiptMode.finalPaid) {
    final paidVal = paid ?? total;
    final changeVal = change ?? (paidVal - total);

    await printer.leftRight('Subtotal', money.format(subtotal));
    if (tax > 0) await printer.leftRight('Tax', money.format(tax));
    if (service > 0) await printer.leftRight('Service', money.format(service));

    await printer.leftRight('TOTAL', money.format(total), size: 2);
    await printer.leftRight('Paid', money.format(paidVal));
    await printer.leftRight('Change', money.format(changeVal));
  } else {
    // Unpaid ticket
    await printer.leftRight('Amount Due', money.format(total), size: 2);
    await printer.newline();
    await printer.println('*** UNPAID (Pay Later) ***', align: 1);
    await printer.println('This is not a tax receipt', align: 1);
  }

  // ===== FOOTER =====
  await printer.newline();
  await printer.println('Thank you!', align: 1);

  if ((footerNote ?? '').trim().isNotEmpty) {
    await printer.println(footerNote!.trim(), align: 1);
  }

  await printer.newline();
  await printer.cut();
}

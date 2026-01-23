import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'receipt_printer.dart';
import 'printer_facade.dart'; // for PrinterBrand

/// Receipt visual style selector.
enum ReceiptStyle { standard, simpleText, blankNote }

/// Which business state the receipt represents.
enum ReceiptMode { finalPaid, unpaid }

/// Unified function for all receipt styles and modes.
/// - `style` controls visuals (logo/brand vs text-only vs blank-note)
/// - `mode` controls totals section (paid/change vs amount due)
Future<void> printRestaurantReceipt(
  ReceiptPrinter printer, {
  ReceiptStyle style = ReceiptStyle.standard,
  ReceiptMode mode = ReceiptMode.finalPaid,

  // Branding (logo handled via logoBytes for standard style)
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

  // Optional logo (used only by standard style)
  Uint8List? logoBytes,
}) async {
  // =========================
  // 1) PREPARE COMMON VALUES
  // =========================
  final now = time ?? DateTime.now();
  final money =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);



  Future<void> headerStandard() async {
    // ---- Logo (optional) ----

    final bytes = logoBytes;
    if (bytes != null) {
      await printer.printImage(bytes, align: AlignX.center);
      await printer.newline();
    }

    // ---- Brand info ----
    await printer.println(brand.name.toUpperCase(), size: 2, align: 1);

    final address = (brand.address ?? '').trim();
    if (address.isNotEmpty) {
      await printer.println(address, align: 1);
    }

    final phone = (brand.phone ?? '').trim();
    if (phone.isNotEmpty) {
      await printer.println('Tel: $phone', align: 1);
    }

    await printer.newline();
  }

  Future<void> metaStandard() async {
    await printer.leftRight('Bill No.', billNumber);
    await printer.leftRight('Date', dateStr);

    final tableText = (table ?? '').trim();
    if (tableText.isNotEmpty) {
      await printer.leftRight('Table', tableText);
    }

    await printer.leftRight('Order By', cashierOrOrderer);
    await printer.divider();
  }

  Future<void> itemsSection() async {
    // Print setiap item:
    // - "qty x name"
    // - total harga rata kanan
    // - addons (kalau ada) diawali "+"

    for (final it in items) {
      final name = '${it['name']}';
      final qty = (it['qty'] ?? 1).toString();
      final lineTotal = (it['total'] ?? 0) as num;

      await printer.println('$qty x $name');
      await printer.leftRight('', money.format(lineTotal));

      // Add-ons (if any)
      final addons = it['addons'];
      if (addons is List) {
        for (final a in addons) {
          final n = (a is Map) ? (a['name'] ?? a.toString()) : a.toString();
          final s = (n ?? '').toString().trim();
          if (s.isNotEmpty) {
            await printer.println('  + $s');
          }
        }
      }
    }
  }

  Future<void> totalsFinalPaid() async {
    // Untuk final paid:
    // - tampil subtotal/tax/service/total
    // - tampil paid dan change
    final paidVal = paid ?? total;
    final changeVal = change ?? (paidVal - total);

    await printer.leftRight('Subtotal', money.format(subtotal));
    if (tax > 0) {
      await printer.leftRight('Tax', money.format(tax));
    }
    if (service > 0) {
      await printer.leftRight('Service', money.format(service));
    }

    await printer.leftRight('TOTAL', money.format(total), size: 2);
    await printer.leftRight('Paid', money.format(paidVal));
    await printer.leftRight('Change', money.format(changeVal));
  }

  Future<void> totalsUnpaid() async {
    // Untuk unpaid:
    // - hanya amount due
    // - plus reminder text
    await printer.leftRight('Amount Due', money.format(total), size: 2);
    await printer.newline();
    await printer.println('*** UNPAID (Pay Later) ***', align: 1);
    await printer.println('This is not a tax receipt', align: 1);
  }

  Future<void> footer({required bool includeThanks}) async {
    // Footer:
    // - spacing
    // - optional thanks
    // - optional footerNote
    // - cut paper
    await printer.newline();

    if (includeThanks) {
      await printer.println('Thank you!', align: 1);
    }

    final note = (footerNote ?? '').trim();
    if (note.isNotEmpty) {
      await printer.println(note, align: 1);
    }

    await printer.newline();
    await printer.cut();
  }

  // =========================
  // 3) RENDER BY STYLE
  // =========================
  switch (style) {
    case ReceiptStyle.standard:
      // Standard:
      // - logo (optional)
      // - brand full
      // - meta full
      // - items
      // - totals by mode
      // - footer + thanks
      await headerStandard();
      await metaStandard();

      await itemsSection();
      await printer.divider();

      if (mode == ReceiptMode.finalPaid) {
        await totalsFinalPaid();
      } else {
        await totalsUnpaid();
      }

      await footer(includeThanks: true);
      break;

    case ReceiptStyle.simpleText:
      // SimpleText:
      // - no logo
      // - still shows brand + meta
      // - items
      // - totals by mode (paid/change emphasized)
      final name = brand.name.trim();
      if (name.isNotEmpty) {
        await printer.println(name.toUpperCase(), size: 2, align: 1);
      }

      final address = (brand.address ?? '').trim();
      if (address.isNotEmpty) {
        await printer.println(address, align: 1);
      }

      final phone = (brand.phone ?? '').trim();
      if (phone.isNotEmpty) {
        await printer.println('Tel: $phone', align: 1);
      }

      await printer.divider();

      if (billNumber.trim().isNotEmpty) {
        await printer.leftRight('Bill No.', billNumber);
      }

      await printer.leftRight('Date', dateStr);

      final tableText = (table ?? '').trim();
      if (tableText.isNotEmpty) {
        await printer.leftRight('Table', tableText);
      }

      await printer.leftRight('Order By', cashierOrOrderer);
      await printer.divider();

      await itemsSection();
      await printer.divider();

      if (mode == ReceiptMode.finalPaid) {
        final paidVal = paid ?? total;
        final changeVal = change ?? (paidVal - total);

        await printer.leftRight('Subtotal', money.format(subtotal));
        if (tax > 0) {
          await printer.leftRight('Tax', money.format(tax));
        }
        if (service > 0) {
          await printer.leftRight('Service', money.format(service));
        }

        await printer.leftRight('TOTAL', money.format(total), size: 2);
        await printer.leftRight('PAID', money.format(paidVal), size: 1);
        await printer.leftRight('CHANGE', money.format(changeVal), size: 1);
      } else {
        await totalsUnpaid();
      }

      await footer(includeThanks: true);
      break;

    case ReceiptStyle.blankNote:
      // BlankNote:
      // - no brand, no bill number
      // - show date big
      // - items
      // - subtotal + total
      // - footer without thanks (pure blank style)
      await printer.println(
        DateFormat('dd MMM yyyy  HH:mm').format(now),
        size: 2,
        align: 1,
      );
      await printer.divider();

      await itemsSection();
      await printer.divider();

      await printer.leftRight('Subtotal', money.format(subtotal));
      await printer.leftRight('TOTAL', money.format(total), size: 2);

      await footer(includeThanks: false);
      break;
  }
}

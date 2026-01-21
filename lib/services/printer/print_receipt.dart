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
  final now = time ?? DateTime.now();
  final money = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

  // --- small helpers ---------------------------------------------------------
  Future<void> _headerStandard() async {
    if (logoBytes != null) {
      await printer.printImage(logoBytes!, align: AlignX.center);
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
  }

  Future<void> _metaStandard() async {
    await printer.leftRight('Bill No.', billNumber);
    await printer.leftRight('Date', dateStr);
    if ((table ?? '').trim().isNotEmpty) {
      await printer.leftRight('Table', table!.trim());
    }
    await printer.leftRight('Order By', cashierOrOrderer);
    await printer.divider();
  }

  Future<void> _itemsSection() async {
    for (final it in items) {
      final name = '${it['name']}';
      final qty = (it['qty'] ?? 1).toString();
      final lineTotal = (it['total'] ?? 0) as num;

      // Item line (qty x name)
      await printer.println('$qty x $name');
      // Price aligned right
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

  Future<void> _totalsFinalPaid() async {
    final paidVal = paid ?? total;
    final changeVal = change ?? (paidVal - total);

    await printer.leftRight('Subtotal', money.format(subtotal));
    if (tax > 0)     await printer.leftRight('Tax',     money.format(tax));
    if (service > 0) await printer.leftRight('Service', money.format(service));
    await printer.leftRight('TOTAL',  money.format(total),  size: 2);
    await printer.leftRight('Paid',   money.format(paidVal));
    await printer.leftRight('Change', money.format(changeVal));
  }

  Future<void> _totalsUnpaid() async {
    await printer.leftRight('Amount Due', money.format(total), size: 2);
    await printer.newline();
    await printer.println('*** UNPAID (Pay Later) ***', align: 1);
    await printer.println('This is not a tax receipt', align: 1);
  }

  Future<void> _footer([bool includeThanks = true]) async {
    await printer.newline();
    if (includeThanks) {
      await printer.println('Thank you!', align: 1);
    }
    if ((footerNote ?? '').trim().isNotEmpty) {
      await printer.println(footerNote!.trim(), align: 1);
    }
    await printer.newline();
    await printer.cut();
  }
  // ---------------------------------------------------------------------------

  // =========================
  // RENDER by RECEIPT STYLE
  // =========================
  switch (style) {
    case ReceiptStyle.standard:
      // Your current behavior (with optional logo + full brand)
      await _headerStandard();
      await _metaStandard();

      // Items
      await _itemsSection();
      await printer.divider();

      // Totals by mode
      if (mode == ReceiptMode.finalPaid) {
        await _totalsFinalPaid();
      } else {
        await _totalsUnpaid();
      }

      await _footer(true);
      break;

    case ReceiptStyle.simpleText:
      // Text-only header (no logo), but still shows brand & bill number
      if ((brand.name).trim().isNotEmpty) {
        await printer.println(brand.name.toUpperCase(), size: 2, align: 1);
      }
      if ((brand.address ?? '').trim().isNotEmpty) {
        await printer.println(brand.address!.trim(), align: 1);
      }
      if ((brand.phone ?? '').trim().isNotEmpty) {
        await printer.println('Tel: ${brand.phone!.trim()}', align: 1);
      }
      await printer.divider();

      // Meta (still include bill/date/table/cashier)
      if (billNumber.trim().isNotEmpty) {
        await printer.leftRight('Bill No.', billNumber);
      }
      await printer.leftRight('Date', dateStr);
      if ((table ?? '').trim().isNotEmpty) {
        await printer.leftRight('Table', table!.trim());
      }
      await printer.leftRight('Order By', cashierOrOrderer);
      await printer.divider();

      // Items
      await _itemsSection();
      await printer.divider();

      // Totals by mode (keep paid/change emphasized a bit)
      if (mode == ReceiptMode.finalPaid) {
        final paidVal = paid ?? total;
        final changeVal = change ?? (paidVal - total);

        await printer.leftRight('Subtotal', money.format(subtotal));
        if (tax > 0)     await printer.leftRight('Tax',     money.format(tax));
        if (service > 0) await printer.leftRight('Service', money.format(service));
        await printer.leftRight('TOTAL',   money.format(total), size: 2);
        await printer.leftRight('PAID',    money.format(paidVal), size: 1);
        await printer.leftRight('CHANGE',  money.format(changeVal), size: 1);
      } else {
        await _totalsUnpaid();
      }

      await _footer(true);
      break;

    case ReceiptStyle.blankNote:
      // BLANK NOTE: no brand, no bill number — only date, items, subtotal/total
      // Date BIG & centered
      await printer.println(DateFormat('dd MMM yyyy  HH:mm').format(now), size: 2, align: 1);
      await printer.divider();

      // Items only
      await _itemsSection();
      await printer.divider();

      // Subtotal + TOTAL big (ignore paid/change per your request)
      await printer.leftRight('Subtotal', money.format(subtotal));
      await printer.leftRight('TOTAL', money.format(total), size: 2);

      // Minimal footer (no thanks if you want pure blank; set to false)
      await _footer(false);
      break;
  }
}

import 'package:intl/intl.dart';
import 'receipt_printer.dart';

Future<void> printRestaurantReceipt(
  ReceiptPrinter printer, {
  required String restaurantName,
  String? address,
  String? phone,
  required String billNumber,
  String? table,
  required String cashierOrOrderer,
  required List<Map<String, dynamic>> items, // [{name, qty, price, total, addons?[]}]
  required double subtotal,
  double tax = 0,
  double service = 0,
  required double total,
  required double paid,
  required double change,
  DateTime? time,
}) async {
  final now = time ?? DateTime.now();
  final money = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  await printer.println('== $restaurantName ==', size: 2, align: 1);
  if ((address ?? '').isNotEmpty) await printer.println(address!, align: 1);
  if ((phone ?? '').isNotEmpty) await printer.println('Telp: $phone', align: 1);
  await printer.newline();

  await printer.leftRight('No. Bill', billNumber);
  await printer.leftRight('Tanggal', DateFormat('dd/MM/yyyy HH:mm').format(now));
  if ((table ?? '').isNotEmpty) await printer.leftRight('Meja', table!);
  await printer.leftRight('Kasir', cashierOrOrderer);
  await printer.divider();

  for (final it in items) {
    final name = '${it['name']}';
    final qty  = (it['qty'] ?? 1).toString();
    final totalItem = (it['total'] ?? 0) as num;
    await printer.println('$qty x $name');
    await printer.leftRight('', money.format(totalItem));
    final addons = it['addons'];
    if (addons is List) {
      for (final a in addons) {
        await printer.println('  + ${a['name'] ?? ''}');
      }
    }
  }

  await printer.divider();
  await printer.leftRight('Subtotal', money.format(subtotal));
  if (tax > 0)     await printer.leftRight('Pajak',   money.format(tax));
  if (service > 0) await printer.leftRight('Service', money.format(service));
  await printer.leftRight('Total', money.format(total), size: 2);
  await printer.leftRight('Bayar', money.format(paid));
  await printer.leftRight('Kembali', money.format(change));
  await printer.newline();

  await printer.println('Terima kasih!', align: 1);
  await printer.newline();
  await printer.cut();
}

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

Future<File> exportRecapToCSV({
  required List<Order> orders,
  String format = 'summary', // 'summary', 'order', 'item'
  String? customPath,
}) async {
  final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final fileName = 'daily_recap_${format}_$now.csv';
  final formatter = NumberFormat.decimalPattern();

  List<List<dynamic>> csvData = [];

  if (orders.isEmpty) {
    csvData.add(['No data available']);
  } else {
    switch (format) {
      case 'order':
        csvData = _buildOrderFormat(orders, formatter);
        break;
      case 'item':
        csvData = _buildItemFormat(orders, formatter);
        break;
      case 'summary':
      default:
        csvData = _buildSummaryFormat(orders, formatter);
        break;
    }
  }

  final csvString = const ListToCsvConverter().convert(csvData);
  final directory =
      customPath != null
          ? Directory(customPath)
          : await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  return file.writeAsString(csvString);
}

List<List<dynamic>> _buildOrderFormat(
  List<Order> orders,
  NumberFormat formatter,
) {
  return [
    [
      'Date',
      'Orderer',
      'Table',
      'Status',
      'Total (Rp)',
      'Payment Method',
      'Mode',
      'Event Date',
      'Customer Phone',
      'Notes',
    ],
    ...orders.map(
      (o) => [
        DateFormat('yyyy-MM-dd HH:mm').format(o.time),
        o.orderer,
        o.tableNumber ?? '-',
        o.status,
        formatter.format(o.total),
        o.paymentMethod ?? '-',
        o.mode,
        o.eventDate ?? '',
        o.customerPhone ?? '',
        o.notes ?? '',
      ],
    ),
  ];
}

List<List<dynamic>> _buildItemFormat(
  List<Order> orders,
  NumberFormat formatter,
) {
  final data = [
    [
      'Date',
      'Orderer',
      'Mode',
      'Event Date',
      'Customer Phone',
      'Notes',
      'Item',
      'Qty',
      'Price (Rp)',
      'Add-ons',
      'Subtotal (Rp)',
    ],
  ];

  for (final order in orders) {
    for (final item in order.items) {
      data.add([
        DateFormat('yyyy-MM-dd HH:mm').format(order.time),
        order.orderer,
        order.mode,
        order.eventDate != null
            ? DateFormat('yyyy-MM-dd').format(order.eventDate!)
            : '',
        order.customerPhone ?? '',
        order.notes ?? '',
        item.name,
        item.quantity.toString(),
        formatter.format(item.price),
        item.addons.isNotEmpty ? item.addons.join(', ') : '-',
        formatter.format(item.total),
      ]);
    }
  }
  return data;
}

List<List<dynamic>> _buildSummaryFormat(
  List<Order> orders,
  NumberFormat formatter,
) {
  final grouped = <String, List<Order>>{};
  for (final order in orders) {
    final dateKey = DateFormat('yyyy-MM-dd').format(order.time);
    grouped.putIfAbsent(dateKey, () => []).add(order);
  }

  final data = [
    [
      'Date',
      'Orders',
      'Paid (Rp)',
      'Unpaid (Rp)',
      'Total (Rp)',
      'Catering Orders',
      'Restaurant Orders',
    ],
  ];

  int totalOrders = 0, cateringOrders = 0, restaurantOrders = 0;
  double totalPaid = 0, totalUnpaid = 0, totalAll = 0;

  for (final entry in grouped.entries) {
    final date = entry.key;
    final dayOrders = entry.value;
    final total = dayOrders.fold(0.0, (sum, o) => sum + o.total);
    final paid = dayOrders
        .where((o) => o.status == 'paid')
        .fold(0.0, (sum, o) => sum + o.total);
    final unpaid = total - paid;
    final catering = dayOrders.where((o) => o.mode == 'catering').length;
    final resto = dayOrders.where((o) => o.mode == 'restaurant').length;

    data.add([
      date,
      dayOrders.length.toString(),
      formatter.format(paid),
      formatter.format(unpaid),
      formatter.format(total),
      catering.toString(),
      resto.toString(),
    ]);

    totalOrders += dayOrders.length;
    cateringOrders += catering;
    restaurantOrders += resto;
    totalPaid += paid;
    totalUnpaid += unpaid;
    totalAll += total;
  }

  // Add grand total row
  data.add([
    'TOTAL',
    '$totalOrders order(s)',
    formatter.format(totalPaid),
    formatter.format(totalUnpaid),
    formatter.format(totalAll),
    cateringOrders.toString(),
    restaurantOrders.toString(),
  ]);

  // Add payment breakdown section
  data.add([]);
  data.add(['Payment Breakdown']);
  data.add(['Method', 'Total (Rp)']);

  final paymentMap = <String, double>{};
  for (final order in orders) {
    if (order.status == 'paid') {
      final method = order.paymentMethod ?? 'Unknown';
      paymentMap[method] = (paymentMap[method] ?? 0) + order.total;
    }
  }

  for (final entry in paymentMap.entries) {
    data.add([entry.key, formatter.format(entry.value)]);
  }

  return data;
}

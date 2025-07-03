// lib/utils/export_csv.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/order.dart';

/// Exports a list of [Order]s to a CSV file.
/// Optionally specify [customPath] to save to a specific directory.
Future<File> exportRecapSummaryToCSV({
  required List<Order> orders,
  String? customPath,
}) async {
  // Group orders by date
  final Map<String, List<Order>> grouped = {};
  for (var order in orders) {
    final date = DateFormat('yyyy-MM-dd').format(order.time);
    grouped.putIfAbsent(date, () => []).add(order);
  }

  // Prepare CSV data
  final List<List<dynamic>> csvData = [
    ['Date', 'Order Count', 'Total (Rp)'],
  ];

  for (var entry in grouped.entries) {
    final date = entry.key;
    final dayOrders = entry.value;
    final total = dayOrders.fold(0.0, (sum, o) => sum + o.total);

    csvData.add([date, dayOrders.length, total.toStringAsFixed(0)]);
  }

  final csvString = const ListToCsvConverter().convert(csvData);

  // Determine output path
  final dir =
      customPath != null
          ? Directory(customPath)
          : await getApplicationDocumentsDirectory();

  final file = File('${dir.path}/daily_recap.csv');
  return file.writeAsString(csvString);
}

Future<File> exportRecapDetailToCSV({
  required List<Order> orders,
  String? customPath,
}) async {
  final List<List<dynamic>> csvData = [
    ['Date', 'Orderer', 'Item', 'Qty', 'Addons', 'Subtotal (Rp)', 'Status'],
  ];

  for (var order in orders) {
    final date = DateFormat('yyyy-MM-dd').format(order.time);
    for (var item in order.items) {
      final addonText = item.addons.isNotEmpty ? item.addons.join(', ') : '-';
      csvData.add([
        date,
        order.orderer.isNotEmpty ? order.orderer : '-',
        item.name,
        item.quantity,
        addonText,
        item.total.toStringAsFixed(0),
        order.status,
      ]);
    }
  }

  final csvString = const ListToCsvConverter().convert(csvData);
  final dir =
      customPath != null
          ? Directory(customPath)
          : await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/daily_recap_detailed.csv');
  return file.writeAsString(csvString);
}

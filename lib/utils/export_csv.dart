import 'dart:io';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<File> exportRecapToCSV({String? customPath}) async {
  final orders = Hive.box<Order>('orders').values.toList();

  final buffer = StringBuffer();
  buffer.writeln('Date,Orderer,Item,Quantity,Price,Subtotal');

  for (final order in orders) {
    for (final item in order.items) {
      final addons = item.addons.join(' + ');
      final itemName = addons.isNotEmpty ? '${item.name} ($addons)' : item.name;
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(order.time)},'
        '${order.orderer},'
        '$itemName,'
        '${item.quantity},'
        '${item.price.toStringAsFixed(0)},'
        '${item.total.toStringAsFixed(0)}',
      );
    }
  }

  final filename =
      'daily_recap_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

  // If a custom path is provided, save there
  String path;
  if (customPath != null) {
    path = p.join(customPath, filename);
  } else {
    final dir = await getApplicationDocumentsDirectory();
    path = p.join(dir.path, filename);
  }

  final file = File(path);
  await file.writeAsString(buffer.toString());

  return file;
}

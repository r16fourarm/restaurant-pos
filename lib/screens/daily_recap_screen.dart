import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'daily_order_detail_screen.dart';
import '../utils/export_csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart'; // New import

class DailyRecapScreen extends StatelessWidget {
  const DailyRecapScreen({super.key});

  Future<void> _confirmAndExportCSV(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Daily Recap'),
        content: const Text(
          'Do you want to export all daily recap data to a CSV file?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Export'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _exportCSV(context);
    }
  }

  Future<void> _exportCSV(BuildContext context) async {
    try {
      File file;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final outputPath = await FilePicker.platform.getDirectoryPath();
        if (outputPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export cancelled.')),
          );
          return;
        }
        file = await exportRecapToCSV(customPath: outputPath);

        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to: ${file.path}')),
          );
        }
      } else {
        file = await exportRecapToCSV();
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '📊 Daily Recap CSV',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = Hive.box<Order>('orders').values.toList();

    final Map<String, List<Order>> recapMap = {};
    for (var order in orders) {
      final dateKey = DateFormat('yyyy-MM-dd').format(order.time);
      recapMap.putIfAbsent(dateKey, () => []).add(order);
    }

    final sortedKeys =
        recapMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Recap')),
      body: recapMap.isEmpty
          ? const Center(child: Text('No sales data available.'))
          : ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final date = sortedKeys[index];
                final dayOrders = recapMap[date]!;
                final total = dayOrders.fold(0.0, (sum, o) => sum + o.total);

                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(date)),
                  ),
                  subtitle: Text(
                    '${dayOrders.length} order(s) • Total: Rp ${total.toStringAsFixed(0)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyOrderDetailScreen(date: date),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.download),
        label: const Text('Export CSV'),
        onPressed: () => _confirmAndExportCSV(context),
      ),
    );
  }
}

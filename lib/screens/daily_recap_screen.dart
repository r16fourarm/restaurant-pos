import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../models/order.dart';
import '../utils/export_csv.dart';
import 'daily_order_detail_screen.dart';

class DailyRecapScreen extends StatefulWidget {
  const DailyRecapScreen({super.key});

  @override
  State<DailyRecapScreen> createState() => _DailyRecapScreenState();
}

class _DailyRecapScreenState extends State<DailyRecapScreen> {
  DateTime? _selectedDate;
  String _statusFilter = 'all'; // all, paid, unpaid

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  List<Order> _getFilteredOrders() {
    final allOrders = Hive.box<Order>('orders').values.toList();

    return allOrders.where((order) {
      final matchStatus =
          _statusFilter == 'all' || order.status == _statusFilter;
      final matchDate = _selectedDate == null ||
          DateFormat('yyyy-MM-dd').format(order.time) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate!);
      return matchStatus && matchDate;
    }).toList();
  }

  Map<String, List<Order>> _groupByDate(List<Order> orders) {
    final map = <String, List<Order>>{};
    for (var order in orders) {
      final key = DateFormat('yyyy-MM-dd').format(order.time);
      map.putIfAbsent(key, () => []).add(order);
    }
    return map;
  }

  Future<void> _confirmAndExportCSV(BuildContext context) async {
  String? selectedFormat = await showDialog<String>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: const Text('Choose Export Format'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'summary'),
            child: const Text('📊 Daily Summary'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'order'),
            child: const Text('📦 Per Order Details'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'item'),
            child: const Text('🍽️ Per Item Details'),
          ),
        ],
      );
    },
  );

  if (selectedFormat != null) {
    await _exportCSV(context, selectedFormat);
  }
}


Future<void> _exportCSV(BuildContext context, String format) async {
  try {
    final orders = _getFilteredOrders();
    File file;

    // Pick export path (desktop) or auto (mobile)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final outputPath = await FilePicker.platform.getDirectoryPath();
      if (outputPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled.')),
        );
        return;
      }

      // Use different filename based on format
      file = await exportRecapToCSV(
        orders: orders,
        customPath: outputPath,
        format: format,
      );

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: ${file.path}')),
        );
      }
    } else {
      file = await exportRecapToCSV(orders: orders, format: format);
      await Share.shareXFiles([XFile(file.path)], text: '📊 Daily Recap CSV');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to export: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    final recapMap = _groupByDate(filteredOrders);
    final sortedDates = recapMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Recap'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter by Status',
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('Show All')),
              PopupMenuItem(value: 'paid', child: Text('Paid Only')),
              PopupMenuItem(value: 'unpaid', child: Text('Unpaid Only')),
            ],
          ),
          IconButton(
            tooltip: 'Filter by Date',
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
          if (_selectedDate != null)
            IconButton(
              tooltip: 'Clear Date Filter',
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
            ),
        ],
      ),
      body: recapMap.isEmpty
          ? const Center(child: Text('No sales data available.'))
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (_, index) {
                final date = sortedDates[index];
                final dayOrders = recapMap[date]!;
                final total = dayOrders.fold(0.0, (sum, o) => sum + o.total);
                final paid = dayOrders
                    .where((o) => o.status == 'paid')
                    .fold(0.0, (sum, o) => sum + o.total);
                final unpaid = total - paid;

                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('EEEE, dd MMM yyyy')
                      .format(DateTime.parse(date))),
                  subtitle: Text(
                    '${dayOrders.length} order(s)\n💵 Paid: Rp ${paid.toStringAsFixed(0)} • ❌ Unpaid: Rp ${unpaid.toStringAsFixed(0)}',
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

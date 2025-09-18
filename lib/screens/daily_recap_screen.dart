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
  String _modeFilter = 'all'; // 'all', 'restaurant', 'catering',

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
      final matchDate =
          _selectedDate == null ||
          DateFormat('yyyy-MM-dd').format(order.time) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final matchMode =
          _modeFilter == 'all' ||
          order.mode == _modeFilter ||
          (order.mode == 'both' && _modeFilter != 'all');
      return matchStatus && matchDate && matchMode;
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
    if (!context.mounted) return;
    if (selectedFormat != null) {
      await _exportCSV(context, selectedFormat);
    }
  }

  Future<void> _exportCSV(BuildContext context, String format) async {
    try {
      final orders = _getFilteredOrders();
      File file;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final outputPath = await FilePicker.platform.getDirectoryPath();
        if (outputPath == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Export cancelled.')));
          return;
        }
        file = await exportRecapToCSV(
          orders: orders,
          customPath: outputPath,
          format: format,
        );
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to: ${file.path}')),
          );
        }
      } else {
        file = await exportRecapToCSV(orders: orders, format: format);
        await Share.shareXFiles([XFile(file.path)], text: '📊 Daily Recap CSV');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to export: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    final recapMap = _groupByDate(filteredOrders);
    final sortedDates = recapMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final numberFormat = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Recap'),
        actions: [
          // Mode filter (matches BillsScreen)
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _modeFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Modes')),
                DropdownMenuItem(
                  value: 'restaurant',
                  child: Text('Restaurant'),
                ),
                DropdownMenuItem(value: 'catering', child: Text('Catering')),
                DropdownMenuItem(value: 'both', child: Text('Both')),
              ],
              onChanged: (val) => setState(() => _modeFilter = val ?? 'all'),
              style: const TextStyle(fontWeight: FontWeight.bold),
              borderRadius: BorderRadius.circular(10),
              icon: const Icon(Icons.storefront, color: Colors.white),
              dropdownColor: Colors.blue[800],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Filter by Status',
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder:
                (_) => const [
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
      body:
          recapMap.isEmpty
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

                  // If there's at least one catering order on that day, show extra info.
                  final isCateringDay = dayOrders.any(
                    (o) => o.mode == 'catering',
                  );

                  String cateringInfo = '';
                  if (isCateringDay) {
                    final cateringOrders =
                        dayOrders.where((o) => o.mode == 'catering').toList();
                    final eventDates = cateringOrders
                        .map((o) => o.eventDate)
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .toSet()
                        .join(', ');
                    cateringInfo =
                        eventDates.isNotEmpty
                            ? 'Catering Events: $eventDates'
                            : '';
                  }

                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      DateFormat(
                        'EEEE, dd MMM yyyy',
                      ).format(DateTime.parse(date)),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dayOrders.length} order(s)\n'
                          '💵 Paid: Rp ${numberFormat.format(paid)} • ❌ Unpaid: Rp ${numberFormat.format(unpaid)}',
                        ),
                        if (isCateringDay && cateringInfo.isNotEmpty)
                          Text(
                            cateringInfo,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.deepPurple,
                            ),
                          ),
                      ],
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

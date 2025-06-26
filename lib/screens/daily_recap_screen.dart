// lib/screens/daily_recap_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'daily_order_detail_screen.dart';

class DailyRecapScreen extends StatelessWidget {
  const DailyRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Hive.box<Order>('orders').values.toList();

    // Group orders by day and sum the total
    final Map<String, double> recapMap = {};

    for (var order in orders) {
      final dateKey = DateFormat('yyyy-MM-dd').format(order.time);
      recapMap.update(
        dateKey,
        (prev) => prev + order.total,
        ifAbsent: () => order.total,
      );
    }

    final sortedKeys =
        recapMap.keys.toList()..sort((a, b) => b.compareTo(a)); // latest first

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Recap')),
      body:
          recapMap.isEmpty
              ? const Center(child: Text('No sales data available.'))
              : ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final date = sortedKeys[index];
                  final total = recapMap[date]!;

                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      DateFormat(
                        'EEEE, dd MMM yyyy',
                      ).format(DateTime.parse(date)),
                    ),
                    subtitle: Text('Total: Rp ${total.toStringAsFixed(0)}'),
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
    );
  }
}

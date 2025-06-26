// lib/screens/daily_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';

class DailyOrderDetailScreen extends StatelessWidget {
  final String date; // e.g., '2025-06-17'

  const DailyOrderDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Order>('orders');
    final List<Order> filtered = box.values.where((order) {
      final orderDate = DateFormat('yyyy-MM-dd').format(order.time);
      return orderDate == date;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders on $date'),
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('No orders on this day.'))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final order = filtered[index];
                return ListTile(
                  title: Text(
                    order.orderer.isNotEmpty
                        ? 'Order by ${order.orderer}'
                        : 'Unnamed Order',
                  ),
                  subtitle: Text(
                    'Rp ${order.total.toStringAsFixed(0)} • ${DateFormat.Hm().format(order.time)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

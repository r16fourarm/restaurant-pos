// lib/screens/bills_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late Box<Order> _orderBox;

  @override
  void initState() {
    super.initState();
    _orderBox = Hive.box<Order>('orders');
  }

  void _deleteOrder(int index) {
    _orderBox.deleteAt(index);
    setState(() {}); // Refresh UI
  }

  void _clearAllOrders() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Clear All Orders?'),
            content: const Text('This will delete all saved orders.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _orderBox.clear();
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orderBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          if (orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear All',
              onPressed: _clearAllOrders,
            ),
        ],
      ),
      body:
          orders.isEmpty
              ? const Center(child: Text('No orders yet.'))
              : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text(
                      order.orderer.isNotEmpty
                          ? 'Order by ${order.orderer}'
                          : 'Unnamed Order',
                    ),
                    subtitle: Text(
                      '${order.time.toLocal()} - Rp ${order.total.toStringAsFixed(0)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteOrder(index),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );

                      if (result == 'reordered') {
                        setState(() {}); // Refresh order list
                      }
                    },
                  );
                },
              ),
    );
  }
}

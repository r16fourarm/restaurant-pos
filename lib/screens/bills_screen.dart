// lib/screens/bills_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late Box<Order> _orderBox;
  DateTime? _selectedDate;
  String _statusFilter = 'all'; // 'all', 'paid', 'unpaid'

  @override
  void initState() {
    super.initState();
    _orderBox = Hive.box<Order>('orders');
  }

  void _deleteOrder(int index) {
    _orderBox.deleteAt(index);
    setState(() {});
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

  List<Order> _filterOrders(List<Order> orders) {
    return orders.where((order) {
      final matchesDate =
          _selectedDate == null
              ? true
              : DateFormat('yyyy-MM-dd').format(order.time) ==
                  DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final matchesStatus =
          _statusFilter == 'all' || order.status == _statusFilter;

      return matchesDate && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orderBox.values.toList();
    final filtered = _filterOrders(orders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter by Status',
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'all', child: Text('Show All')),
                  const PopupMenuItem(
                    value: 'unpaid',
                    child: Text('Unpaid Only'),
                  ),
                  const PopupMenuItem(value: 'paid', child: Text('Paid Only')),
                ],
            icon: const Icon(Icons.filter_list),
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
          if (filtered.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear All',
              onPressed: _clearAllOrders,
            ),
        ],
      ),
      body:
          filtered.isEmpty
              ? const Center(child: Text('No orders found.'))
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
                      '${DateFormat('yyyy-MM-dd – HH:mm').format(order.time)}\n'
                      'Rp ${order.total.toStringAsFixed(0)} • ${order.status.toUpperCase()}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        final originalIndex = orders.indexOf(order);

                        if (order.status == 'paid') {
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('Cannot Delete Paid Bill'),
                                  content: const Text(
                                    'This bill is already marked as paid and cannot be deleted.',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('Delete Order?'),
                                  content: const Text(
                                    'Are you sure you want to delete this unpaid order?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: const Text('Delete'),
                                      onPressed: () {
                                        _deleteOrder(originalIndex);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                    ),

                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );

                      if (result == 'reordered' || result == 'updated') {
                        // If the order was reordered or updated, refresh the list
                        // If the order was reordered or deleted, refresh the list
                        setState(() {});
                      }
                    },
                  );
                },
              ),
    );
  }
}

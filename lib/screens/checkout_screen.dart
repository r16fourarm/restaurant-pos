// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/cart_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _ordererController = TextEditingController();

  void _confirmOrder() async {
    final cart = context.read<CartModel>();
    final orderer = _ordererController.text;

    final orderItems = cart.items.map((item) {
      return OrderItem(
        name: item.name,
        price: item.price,
        quantity: item.quantity,
      );
    }).toList();

    final total = cart.total;

    final newOrder = Order(
      items: orderItems,
      total: cart.total,
      time: DateTime.now(),
      orderer: orderer,
    );

    final box = Hive.box<Order>('orders');
    await box.add(newOrder);

    cart.clear(); // Clear the cart after confirming

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Saved'),
        content: Text(
          'Thank you${orderer.isNotEmpty ? ', $orderer' : ''}!\n'
          'Total: Rp ${total.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    title: Text('${item.name} x ${item.quantity}'),
                    trailing: Text('Rp ${item.totalPrice.toStringAsFixed(0)}'),
                  );
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _ordererController,
              decoration: const InputDecoration(
                labelText: 'Orderer / Table Name (optional)',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total: Rp ${cart.total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirmOrder,
              child: const Text('Confirm Order'),
            ),
          ],
        ),
      ),
    );
  }
}

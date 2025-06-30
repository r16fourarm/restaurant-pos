import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/cart_model.dart';
// import '../models/product.dart';

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
        name: item.product.name,
        price: item.product.price,
        quantity: item.quantity,
        addons: item.addons.map((a) => a.name).toList(),
        addonsPrice: item.addons.fold(0.0, (sum, a) => (sum as double)+ a.price) ?? 0.0,
      );
    }).toList();

    final total = cart.total;

    final newOrder = Order(
      items: orderItems,
      total: total,
      time: DateTime.now(),
      orderer: orderer,
    );

    final box = Hive.box<Order>('orders');
    await box.add(newOrder);

    cart.clear();

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
                    title: Text('${item.product.name} x ${item.quantity}'),
                    subtitle: (item.addons.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.addons
                                .map((addon) => Text('- ${addon.name} (Rp ${addon.price.toStringAsFixed(0)})'))
                                .toList(),
                          )
                        : null,
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

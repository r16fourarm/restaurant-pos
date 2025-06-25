// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_screen.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orderer: ${order.orderer.isNotEmpty ? order.orderer : 'Unnamed'}',
            ),
            Text('Date: ${order.time.toLocal()}'),
            const SizedBox(height: 16),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return ListTile(
                    title: Text('${item.name} x ${item.quantity}'),
                    trailing: Text(
                      'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              'Total: Rp ${order.total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Reorder'),
              onPressed: () {
                final cartModel = context.read<CartModel>();

                // Convert OrderItem to CartItem
                final List<CartItem> newCartItems =
                    order.items.map((item) {
                      return CartItem(
                        id: '', // if needed, or generate a unique ID
                        name: item.name,
                        price: item.price,
                        quantity: item.quantity,
                      );
                    }).toList();

                cartModel.replaceCart(newCartItems);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

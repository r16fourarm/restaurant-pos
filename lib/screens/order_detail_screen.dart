// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  void _reorder(BuildContext context) {
    final cart = context.read<CartModel>();

    for (var item in order.items) {
      final mainProduct = Product(
        name: item.name,
        price: item.price,
        category: 'Restored',
        isAddon: false,
      );

      final addonProducts = item.addons.map((addonName) {
        return Product(
          name: addonName,
          price: 0, // price fallback, unless you later store it in OrderItem
          category: 'Addon',
          isAddon: true,
        );
      }).toList();

      cart.addItem(
        CartItem(
          product: mainProduct,
          quantity: item.quantity,
          addons: addonProducts,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Items added to cart')),
    );

    Navigator.pop(context); // or Navigator.push to cart screen
  }

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
              'Orderer: ${order.orderer.isEmpty ? '-' : order.orderer}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${order.time}',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (_, index) {
                  final OrderItem item = order.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Rp ${item.price.toStringAsFixed(0)}'),

                          if (item.addons.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text('Add-ons:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...item.addons.map((addonName) => Text('- $addonName')),
                          ],

                          const SizedBox(height: 6),
                          Text(
                            'Subtotal: Rp ${(item.total).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Rp ${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _reorder(context),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Reorder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

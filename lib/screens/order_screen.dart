import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';
import '../models/cart_item.dart';
import 'cart_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Fried Rice', 'price': 25000},
    {'id': '2', 'name': 'Noodles', 'price': 22000},
    {'id': '3', 'name': 'Ice Tea', 'price': 8000},
    {'id': '4', 'name': 'Coffee', 'price': 12000},
  ];

  void _addToCart(BuildContext context, Map<String, dynamic> product) {
    final cart = context.read<CartModel>();
    cart.addItem(CartItem(
      id: product['id'],
      name: product['name'],
      price: product['price'].toDouble(),
    ));
  }

  void _goToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _goToBills(BuildContext context) {
    Navigator.pushNamed(context, '/bills');
  }

  void _goToRecap(BuildContext context) {
    Navigator.pushNamed(context, '/recap');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Bills',
            onPressed: () => _goToBills(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Recap',
            onPressed: () => _goToRecap(context),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _goToCart(context),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];

          return ListTile(
            title: Text(product['name']),
            subtitle: Text('Rp ${product['price']}'),
            trailing: ElevatedButton(
              onPressed: () => _addToCart(context, product),
              child: const Text('Add'),
            ),
          );
        },
      ),
    );
  }
}

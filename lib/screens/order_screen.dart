// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  void _addToCart(BuildContext context, Product product) {
    final cart = context.read<CartModel>();
    cart.addItem(
      CartItem(product: product), // ✅ Updated here
    );
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

  void _goToProducts(BuildContext context) {
    Navigator.pushNamed(context, '/products');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _goToProducts(context),
          ),
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
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          final allProducts = box.values.toList();

          final filtered = allProducts.where((p) {
            final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
            final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      items: ['All', 'Food', 'Drink', 'Other']
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching products found.'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text('Rp ${product.price.toStringAsFixed(0)} • ${product.category}'),
                            trailing: ElevatedButton(
                              onPressed: () => _addToCart(context, product),
                              child: const Text('Add'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

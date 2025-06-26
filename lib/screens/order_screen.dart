import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class OrderScreen extends StatelessWidget {
  OrderScreen({super.key});

  final ValueNotifier<String> selectedCategory = ValueNotifier<String>('All');

  void _addToCart(BuildContext context, Product product) {
    final cart = context.read<CartModel>();
    cart.addItem(
      CartItem(
        id: product.key.toString(),
        name: product.name,
        price: product.price,
      ),
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

  @override
  Widget build(BuildContext context) {
    final productBox = Hive.box<Product>('products');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/products'),
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
        valueListenable: productBox.listenable(),
        builder: (context, Box<Product> box, _) {
          final allProducts = box.values.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ValueListenableBuilder<String>(
                  valueListenable: selectedCategory,
                  builder: (context, category, _) {
                    return DropdownButton<String>(
                      value: category,
                      onChanged: (value) {
                        if (value != null) selectedCategory.value = value;
                      },
                      items: ['All', 'Food', 'Drink', 'Other']
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: selectedCategory,
                  builder: (context, category, _) {
                    final filtered = category == 'All'
                        ? allProducts
                        : allProducts.where((p) => p.category == category).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No products in this category.'));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text('Rp ${product.price.toStringAsFixed(0)}'),
                          trailing: ElevatedButton(
                            onPressed: () => _addToCart(context, product),
                            child: const Text('Add'),
                          ),
                        );
                      },
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

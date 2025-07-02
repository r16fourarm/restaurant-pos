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

  void _addToCart(BuildContext context, Product product) async {
    if (product.isAddon) return; // Prevent adding an addon directly

    final allProducts = Hive.box<Product>('products').values.toList();
    final availableAddons =
        allProducts
            .where(
              (p) =>
                  p.isAddon &&
                  p.addonCategory != null &&
                  p.addonCategory == product.category,
            )
            .toList();

    List<Product> selectedAddons = [];

    if (availableAddons.isNotEmpty) {
      final result = await showDialog(
        context: context,
        builder: (context) {
          final tempSelected = <Product>{};

          return AlertDialog(
            title: const Text('Select Add-ons'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        availableAddons.map((addon) {
                          return CheckboxListTile(
                            title: Text(
                              '${addon.name} (Rp ${addon.price.toStringAsFixed(0)})',
                            ),
                            value: tempSelected.contains(addon),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  tempSelected.add(addon);
                                } else {
                                  tempSelected.remove(addon);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, <Product>[]),
              ),
              ElevatedButton(
                child: const Text('Add to Cart'),
                onPressed: () => Navigator.pop(context, tempSelected.toList()),
              ),
            ],
          );
        },
      );

      if (result != null && result is List<Product>) {
        selectedAddons = result;
      }
    }

    final cart = context.read<CartModel>();
    cart.addItem(
      CartItem(product: product, quantity: 1, addons: selectedAddons),
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
          final allProducts = box.values.where((p) => !p.isAddon).toList();

          final filtered =
              allProducts.where((p) {
                final matchesCategory =
                    _selectedCategory == 'All' ||
                    p.category == _selectedCategory;
                final matchesSearch = p.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
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
                      items:
                          ['All', 'Food', 'Drink', 'Other']
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
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
                child:
                    filtered.isEmpty
                        ? const Center(
                          child: Text('No matching products found.'),
                        )
                        : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                'Rp ${product.price.toStringAsFixed(0)} • ${product.category}',
                              ),
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

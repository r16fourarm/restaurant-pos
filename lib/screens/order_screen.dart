// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'cart_screen.dart';
import '../app_mode_provider.dart';

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
    if (product.isAddon) return;

    final appMode = Provider.of<AppModeProvider>(context, listen: false).mode;

    final allProducts = Hive.box<Product>('products').values.toList();
    final availableAddons =
        allProducts.where((p) {
            final matchesMode = p.mode == appMode || p.mode == 'both';
            return p.isAddon &&
                p.addonCategory == product.category &&
                matchesMode;
          }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    List<Product> selectedAddons = [];

    if (availableAddons.isNotEmpty) {
      final result = await showModalBottomSheet<List<Product>>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final tempSelected = <Product>{};
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Add-ons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ListView(
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
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context, <Product>[]),
                        ),
                        ElevatedButton(
                          child: const Text('Add to Cart'),
                          onPressed:
                              () =>
                                  Navigator.pop(context, tempSelected.toList()),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (result != null) {
        selectedAddons = result;
      } else {
        // If user cancelled, return early
        return;
      }
    }

    // ✅ Move cart.addItem and feedback here:
    final cart = context.read<CartModel>();
    cart.addItem(
      CartItem(product: product, quantity: 1, addons: selectedAddons),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
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
          Consumer2<AppModeProvider, CartModel>(
            builder: (context, modeProvider, cart, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: modeProvider.mode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    dropdownColor: Colors.blue[800],
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: 'restaurant',
                        child: Text('Restaurant'),
                      ),
                      DropdownMenuItem(
                        value: 'catering',
                        child: Text('Catering'),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val == null || val == modeProvider.mode) return;

                      // Only warn/clear if there are items in cart
                      if (cart.items.isNotEmpty) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Switch Business Mode?'),
                                content: const Text(
                                  'Switching mode will clear the current cart. Continue?',
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    child: const Text('Continue'),
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed != true) return;
                        cart.clear();
                      }

                      modeProvider.setMode(val);
                    },
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          final appMode = Provider.of<AppModeProvider>(context).mode;

          final allProducts =
              box.values.where((p) {
                return (p.mode == appMode || p.mode == 'both') && !p.isAddon;
              }).toList();

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
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      borderRadius: BorderRadius.circular(12),
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
                        : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3 / 2,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return _ProductCard(
                              product: product,
                              onTap: () => _addToCart(context, product),
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

class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                isHovered
                    ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// lib/screens/order_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../widgets/app_drawer.dart';
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

    // final cart = context.read<CartModel>();
    // final messenger = ScaffoldMessenger.of(context);

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

      if (!context.mounted) return; // or: if (!mounted) return; inside a State

      if (result != null) {
        selectedAddons = result;
      } else {
        // If user cancelled, return early
        return;
      }
    }

    final cart = context.read<CartModel>();
    cart.addItem(
      CartItem(product: product, quantity: 1, addons: selectedAddons),
    );

    // Modern floating snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Added to cart!')),
          ],
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
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

  void _goToProducts(BuildContext context) {
    Navigator.pushNamed(context, '/products');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      // Make the drawer edge-swipe area small to avoid stealing touches
      drawerEdgeDragWidth: 24,

      appBar: AppBar(
        // Prevent auto-hamburger that can overlap gestures
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: Builder(
          builder:
              (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
        ),
        titleSpacing: 0,
        title: const Text('Order Menu'),
        actions: [
          // Keep only the cart here (with badge)
          Consumer<CartModel>(
            builder: (context, cart, child) {
              int cartCount = cart.items.fold(0, (p, e) => p + e.quantity);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: 'Cart',
                    onPressed: () => _goToCart(context),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 5,
                          minHeight: 5,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),

          // Our own top toolbar row to avoid AppBar crowding/overlap
          _TopActionsBar(
            onSettings: () => Navigator.pushNamed(context, '/settings'),
            onProducts: () => _goToProducts(context),
            onBills: () => _goToBills(context),
            onRecap: () => _goToRecap(context),
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Product>('products').listenable(),
              builder: (context, Box<Product> box, _) {
                final appMode = Provider.of<AppModeProvider>(context).mode;

                final allProducts =
                    box.values
                        .where(
                          (p) =>
                              (p.mode == appMode || p.mode == 'both') &&
                              !p.isAddon,
                        )
                        .toList();

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
                                      childAspectRatio: 0.9,
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
          ),
        ],
      ),
    );
  }
}

/// Top toolbar row (buttons + mode switcher) to avoid AppBar crowding.
class _TopActionsBar extends StatelessWidget {
  final VoidCallback onSettings, onProducts, onBills, onRecap;
  const _TopActionsBar({
    required this.onSettings,
    required this.onProducts,
    required this.onBills,
    required this.onRecap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          // Scrollable action icons (no crowding on small screens)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                // children: [
                //   // IconButton(
                //   //   icon: const Icon(Icons.settings),
                //   //   tooltip: 'Settings',
                //   //   onPressed: onSettings,
                //   // ),
                //   // IconButton(
                //   //   icon: const Icon(Icons.food_bank),
                //   //   tooltip: 'Products',
                //   //   onPressed: onProducts,
                //   // ),
                //   // IconButton(
                //   //   icon: const Icon(Icons.note),
                //   //   tooltip: 'Bills',
                //   //   onPressed: onBills,
                //   // ),
                //   // IconButton(
                //   //   icon: const Icon(Icons.note_alt),
                //   //   tooltip: 'Recap',
                //   //   onPressed: onRecap,
                //   // ),
                // ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Fixed-width mode switcher at far right
          SizedBox(
            width: 100,
            height: kToolbarHeight - 10,
            child: Consumer2<AppModeProvider, CartModel>(
              builder: (context, modeProvider, cart, _) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: modeProvider.mode,
                      isExpanded: true,
                      dropdownColor: Colors.blue[800],
                      borderRadius: BorderRadius.circular(12),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
          ),
        ],
      ),
    );
  }
}

// ---- Optional: Unused HoverableModeIcon (kept from your file) ----
class _HoverableModeIcon extends StatefulWidget {
  final bool isRestaurant;
  final VoidCallback onPressed;
  const _HoverableModeIcon({
    required this.isRestaurant,
    required this.onPressed,
  });

  @override
  State<_HoverableModeIcon> createState() => _HoverableModeIconState();
}

class _HoverableModeIconState extends State<_HoverableModeIcon> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color normalColor = Colors.white;
    final Color hoverColor = Colors.amber;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: IconButton(
        icon: Icon(
          widget.isRestaurant ? Icons.restaurant : Icons.local_shipping,
          color: isHovered ? hoverColor : normalColor,
        ),
        onPressed: widget.onPressed,
        tooltip:
            widget.isRestaurant ? 'Switch to Catering' : 'Switch to Restaurant',
      ),
    );
  }
}

// ---- Product Card with Border on Hover (unchanged) ----
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
    final hasPhoto =
        widget.product.imagePath != null &&
        widget.product.imagePath!.isNotEmpty;

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
            border: Border.all(
              color: isHovered ? Colors.blueAccent : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow:
                isHovered
                    ? [
                      const BoxShadow(
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child:
                        hasPhoto
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(widget.product.imagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                            : Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[500],
                                size: 36,
                              ),
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    widget.product.category,
                    style: const TextStyle(fontSize: 11),
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

import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _category = 'Food';
  Product? _editingProduct;

  void _showForm([Product? product]) {
    if (product != null) {
      _editingProduct = product;
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _category = product.category;
    } else {
      _editingProduct = null;
      _nameController.clear();
      _priceController.clear();
      _category = 'Food';
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Enter name' : null,
                  ),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) => value!.isEmpty ? 'Enter price' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items:
                        ['Food', 'Drink', 'Other']
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => _category = val!,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text;
                    final price = double.tryParse(_priceController.text) ?? 0;

                    if (_editingProduct != null) {
                      _editingProduct!
                        ..name = name
                        ..price = price
                        ..category = _category
                        ..save();
                    } else {
                      Hive.box<Product>('products').add(
                        Product(name: name, price: price, category: _category),
                      );
                    }

                    Navigator.pop(context);
                  }
                },
                child: Text(product == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Product?'),
            content: const Text(
              'Are you sure you want to delete this product?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Delete'),
                onPressed: () {
                  product.delete();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          final products = box.values.toList();

          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(
                  'Rp ${product.price.toStringAsFixed(0)} • ${product.category}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showForm(product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(context, product),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

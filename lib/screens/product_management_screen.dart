import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../widgets/app_drawer.dart';

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
  bool _isAddon = false;
  String? _addonCategory;
  String _mode = 'both'; // restaurant, catering, or both
  Product? _editingProduct;
  String? _selectedImagePath;

  void _showForm([Product? product]) {
    if (product != null) {
      _editingProduct = product;
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _category = product.category;
      _isAddon = product.isAddon;
      _addonCategory = product.addonCategory;
      _mode = product.mode;
      _selectedImagePath = product.imagePath;
    } else {
      _editingProduct = null;
      _nameController.clear();
      _priceController.clear();
      _category = 'Food';
      _isAddon = false;
      _addonCategory = null;
      _mode = 'both';
      _selectedImagePath = null;
    }

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(product == null ? 'Add Product' : 'Edit Product'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image picker
                        Column(
                          children: [
                            _selectedImagePath != null &&
                                    _selectedImagePath!.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_selectedImagePath!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, size: 40),
                                ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Add/Change Photo'),
                              onPressed: () async {
                                final path = await pickAndSaveImage();
                                if (path != null) {
                                  setState(() => _selectedImagePath = path);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator:
                              (value) => value!.isEmpty ? 'Enter name' : null,
                        ),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price'),
                          validator:
                              (value) => value!.isEmpty ? 'Enter price' : null,
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
                          onChanged: (val) => setState(() => _category = val!),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _mode,
                          items: [
                            DropdownMenuItem(
                              value: 'restaurant',
                              child: Text('Restaurant'),
                            ),
                            DropdownMenuItem(
                              value: 'catering',
                              child: Text('Catering'),
                            ),
                            DropdownMenuItem(
                              value: 'both',
                              child: Text('Both'),
                            ),
                          ],
                          onChanged:
                              (val) => setState(() => _mode = val ?? 'both'),
                          decoration: const InputDecoration(
                            labelText: 'Product Mode',
                          ),
                        ),
                        CheckboxListTile(
                          value: _isAddon,
                          onChanged:
                              (val) => setState(() => _isAddon = val ?? false),
                          title: const Text('Mark as Add-on'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_isAddon)
                          DropdownButtonFormField<String>(
                            value: _addonCategory,
                            items:
                                ['Food', 'Drink', 'Coffee', 'Tea', 'Other']
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() => _addonCategory = val),
                            decoration: const InputDecoration(
                              labelText: 'Add-on for Category',
                            ),
                            validator: (val) {
                              if (_isAddon && (val == null || val.isEmpty)) {
                                return 'Select a category this add-on applies to';
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
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
                        final price =
                            double.tryParse(_priceController.text) ?? 0;

                        if (_editingProduct != null) {
                          _editingProduct!
                            ..name = name
                            ..price = price
                            ..category = _category
                            ..isAddon = _isAddon
                            ..addonCategory = _isAddon ? _addonCategory : null
                            ..mode = _mode
                            ..imagePath = _selectedImagePath ?? ''
                            ..save();
                        } else {
                          Hive.box<Product>('products').add(
                            Product(
                              name: name,
                              price: price,
                              category: _category,
                              isAddon: _isAddon,
                              addonCategory: _isAddon ? _addonCategory : null,
                              mode: _mode,
                              imagePath: _selectedImagePath ?? '',
                            ),
                          );
                        }

                        Navigator.pop(context);
                      }
                    },
                    child: Text(product == null ? 'Add' : 'Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<String?> pickAndSaveImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailsDir = Directory(
        '${appDir.path}/RestaurantPOS_Thumbnails',
      );

      // **Check & create folder if not exists**
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final savedFile = await file.copy('${thumbnailsDir.path}/$fileName');
      // print("Image saved to: $savedFile.path");
      return savedFile.path;
    }
    return null;
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

  Widget _buildProductTile(Product product) {
    return ListTile(
      leading:
          (product.imagePath != null && product.imagePath!.isNotEmpty)
              ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(product.imagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
              : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image, color: Colors.grey, size: 28),
              ),
      title: Text(product.name),
      subtitle: Text(
        'Rp ${product.price.toStringAsFixed(0)} • ${product.category} • Mode: ${product.mode}'
        '${product.isAddon ? ' • Add-on for ${product.addonCategory ?? '-'}' : ''}',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      drawer: const AppDrawer(),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          final allProducts = box.values.toList();
          final regularProducts = allProducts.where((p) => !p.isAddon).toList();
          final addonProducts = allProducts.where((p) => p.isAddon).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...regularProducts.map(_buildProductTile),
              const SizedBox(height: 24),
              const Divider(),
              const Text(
                'Add-ons',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...addonProducts.map(_buildProductTile),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
              ),
            ],
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

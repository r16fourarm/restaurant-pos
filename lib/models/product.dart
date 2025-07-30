import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 2)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  @HiveField(2)
  String category;

  @HiveField(3)
  bool isAddon;

  @HiveField(4)
  String? addonCategory; // e.g., "Coffee" if this is milk for coffee

  @HiveField(5)
  String mode; // NEW: 'restaurant', 'catering', or 'both'

  @HiveField(6)
  String? imagePath; // Optional image URL for the product

  Product({
    required this.name,
    required this.price,
    required this.category,
    this.isAddon = false,
    this.addonCategory,
    this.mode = 'both', // default = shared by both
    this.imagePath = ''
  });
}

import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 2)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  @HiveField(2)
  String category; // Optional: 'Food', 'Drink', etc.

  Product({
    required this.name,
    required this.price,
    required this.category,
  });
}

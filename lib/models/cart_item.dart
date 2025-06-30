import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'product.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 3)
class CartItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  Product product;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  List<Product> addons;

  CartItem({
    String? id,
    required this.product,
    this.quantity = 1,
    this.addons = const [],
  }) : id = id ?? const Uuid().v4();

  double get totalPrice {
    final addonsTotal = addons.fold(0.0, (sum, addon) => sum + addon.price);
    return (product.price + addonsTotal) * quantity;
  }
}

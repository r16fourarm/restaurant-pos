// lib/models/order_item.dart
import 'package:hive/hive.dart';

part 'order_item.g.dart';

@HiveType(typeId: 1)
class OrderItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  @HiveField(2)
  int quantity;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

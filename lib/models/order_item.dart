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

  @HiveField(3)
  List<String> addons;

  @HiveField(4)
  double addonsPrice;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.addons = const [],
    this.addonsPrice = 0.0,
  });

  double get total => (price + addonsPrice) * quantity;
}

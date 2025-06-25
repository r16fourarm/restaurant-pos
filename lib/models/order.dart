// lib/models/order.dart
import 'package:hive/hive.dart';
import 'order_item.dart';

part 'order.g.dart';

@HiveType(typeId: 0)
class Order extends HiveObject {
  @HiveField(0)
  List<OrderItem> items;

  @HiveField(1)
  double total;

  @HiveField(2)
  DateTime time;

  @HiveField(3)
  String orderer;

  Order({
    required this.items,
    required this.total,
    required this.time,
    required this.orderer,
  });
}

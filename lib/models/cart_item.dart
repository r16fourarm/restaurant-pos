// lib/models/cart_item.dart
class CartItem {
  final String id;        // Unique ID (for example: product ID)
  final String name;      // Product name
  final double price;     // Price per item
  int quantity;           // Quantity in cart

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

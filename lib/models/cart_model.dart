// lib/models/cart_model.dart
import 'package:flutter/material.dart';
import 'cart_item.dart';

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get total => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(CartItem item) {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }

      // print('Added: ${item.name}, qty: ${item.quantity}, total now: $total');

    notifyListeners();
  }

  void increaseQty(CartItem item) {
    item.quantity += 1;
    notifyListeners();
  }

  void decreaseQty(CartItem item) {
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void replaceCart(List<CartItem> newItems) {
    _items
      ..clear()
      ..addAll(newItems);
    notifyListeners();
  }
}

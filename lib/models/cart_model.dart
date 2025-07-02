// lib/models/cart_model.dart
import 'package:flutter/material.dart';
import 'cart_item.dart';
import 'product.dart';

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get total => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(CartItem item) {
  final index = _items.indexWhere((e) =>
    e.product.key == item.product.key &&
    _sameAddons(e.addons, item.addons)
  );

  if (index != -1) {
    _items[index].quantity += item.quantity;
  } else {
    _items.add(item);
  }

  notifyListeners();
}

bool _sameAddons(List<Product> a, List<Product> b) {
  if (a.length != b.length) return false;
  final aKeys = a.map((p) => p.key).toSet();
  final bKeys = b.map((p) => p.key).toSet();
  return aKeys.containsAll(bKeys);
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

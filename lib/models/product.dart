class Product {
  final String name;
  final double price;

  Product(this.name, this.price);
}

class CartItem {
  final Product product;
  int quantity;

  CartItem(this.product, this.quantity);
}

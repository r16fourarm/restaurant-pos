import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/product.dart';
import 'models/order.dart';
import 'models/order_item.dart';
import 'models/cart_model.dart'; // <-- new
import 'screens/order_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/daily_recap_screen.dart';
import 'screens/product_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(OrderItemAdapter());// Register OrderItem adapter
  Hive.registerAdapter(ProductAdapter()); // Register Product  adapter

  // 🧼 TEMP: Clean old 'products' box if schema changed
  // await Hive.deleteBoxFromDisk('products');
  // await Hive.deleteBoxFromDisk('orders');


  await Hive.openBox<Order>('orders'); // ✅ VERY IMPORTANT
  // await Hive.openBox<OrderItem>('orderItems'); // Open OrderItem box
  await Hive.openBox<Product>('products'); // Open Product box
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel(), // <-- Provider for cart
      child: const RestaurantPOSApp(),
    ),
  );
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant POS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:  OrderScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/bills': (context) => const BillsScreen(),
        '/recap': (context) => const DailyRecapScreen(),
        '/products': (context) => const ProductManagementScreen(),
      },
    );
  }
}

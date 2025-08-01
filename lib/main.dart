import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'app_mode_provider.dart';
import 'models/product.dart';
import 'models/order.dart';
import 'models/order_item.dart';
import 'models/cart_model.dart'; // <-- new
import 'screens/order_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/daily_recap_screen.dart';
import 'screens/product_management_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appSupportDir = await getApplicationSupportDirectory();
  // await Hive.initFlutter(appSupportDir.path);

    // Use your own folder, e.g. "RestaurantPOS"
  final myAppDir = Directory('${appSupportDir.parent.path}/RestaurantPOS');
  if (!myAppDir.existsSync()) myAppDir.createSync();

  await Hive.initFlutter(myAppDir.path);

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(OrderItemAdapter()); // Register OrderItem adapter
  Hive.registerAdapter(ProductAdapter()); // Register Product  adapter

  // 🧼 TEMP: Clean old 'products' box if schema changed
  // await Hive.deleteBoxFromDisk('products');
  // await Hive.deleteBoxFromDisk('orders');

  await Hive.openBox<Order>('orders'); // ✅ VERY IMPORTANT
  // await Hive.openBox<OrderItem>('orderItems'); // Open OrderItem box
  await Hive.openBox<Product>('products'); // Open Product box

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppModeProvider(),
        ), // <-- Add this
        ChangeNotifierProvider(create: (_) => CartModel()),
      ],
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
      // home:  OrderScreen(),
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SplashScreen(),
        '/order': (context) => const OrderScreen(),
        '/bills': (context) => const BillsScreen(),
        '/recap': (context) => const DailyRecapScreen(),
        '/products': (context) => const ProductManagementScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/order.dart';
import 'models/order_item.dart';
import 'models/cart_model.dart'; // <-- new
import 'screens/order_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/daily_recap_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(OrderItemAdapter());

  await Hive.openBox<Order>('orders'); // ✅ VERY IMPORTANT

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
      home: const OrderScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/bills': (context) => const BillsScreen(),
        '/recap': (context) => const DailyRecapScreen(),
      },
    );
  }
}

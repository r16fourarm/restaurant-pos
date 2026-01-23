import 'package:flutter/material.dart';

import '../screens/printer_connect_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _goNamed(BuildContext context, String routeName) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text(
                'Restaurant POS',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Connect Printer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrinterConnectScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            // new menu items:
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Orders'),
              onTap:
                  () => _goNamed(context, '/order'), // your OrderScreen route
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Incoming QR Orders'),
              onTap: () => _goNamed(context, '/qrOrders'),
            ),

            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Products'),
              onTap: () => _goNamed(context, '/products'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Bills'),
              onTap: () => _goNamed(context, '/bills'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Recap'),
              onTap: () => _goNamed(context, '/recap'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _goNamed(context, '/settings'),
            ),
            // Add other menu items here…
          ],
        ),
      ),
    );
  }
}

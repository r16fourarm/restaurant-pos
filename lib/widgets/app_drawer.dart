import 'package:flutter/material.dart';

import '../screens/printer_connect_screen.';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Restaurant POS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Connect Printer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterConnectScreen()),
                );
              },
            ),
            // Add other menu items here…
          ],
        ),
      ),
    );
  }
}

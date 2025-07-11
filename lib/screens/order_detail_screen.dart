import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  void _reorder(BuildContext context) {
    final cart = context.read<CartModel>();
    for (var item in order.items) {
      final mainProduct = Product(
        name: item.name,
        price: item.price,
        category: 'Restored',
        isAddon: false,
      );
      final addonProducts = item.addons.map((addonName) {
        return Product(
          name: addonName,
          price: 0,
          category: 'Addon',
          isAddon: true,
        );
      }).toList();
      cart.addItem(CartItem(
        product: mainProduct,
        quantity: item.quantity,
        addons: addonProducts,
      ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Items added to cart')),
    );
    Navigator.pop(context, 'reordered');
  }

  void _markAsPaid(BuildContext context) async {
    final methods = ['Cash', 'QRIS', 'Debit', 'Other'];
    String selected = methods[0];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return DropdownButton<String>(
                value: selected,
                isExpanded: true,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selected = value);
                  }
                },
                items: methods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                order.status = 'paid';
                order.paymentMethod = selected;
                order.paymentTime = DateTime.now();
                order.save();
                Navigator.pop(ctx, 'updated');
              },
            ),
          ],
        );
      },
    );

    if (result == 'updated') {
      Navigator.pop(context, 'updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == 'paid';
    final isCatering = order.mode == 'catering';

    // Format event date if present
    String? readableEventDate;
    if (order.eventDate != null) {
      readableEventDate = DateFormat('yyyy-MM-dd').format(order.eventDate!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode badge
            Row(
              children: [
                Chip(
                  label: Text(
                    order.mode.toUpperCase(),
                    style: TextStyle(
                      color: isCatering ? Colors.purple : Colors.green[800],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  backgroundColor: isCatering ? Colors.purple[50] : Colors.green[50],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Orderer: ${order.orderer.isEmpty ? '-' : order.orderer}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (order.tableNumber?.isNotEmpty == true)
              Text('Table: ${order.tableNumber}', style: const TextStyle(fontSize: 16)),
            // Catering specific fields
            if (isCatering &&
                (order.eventDate != null ||
                    (order.customerPhone?.isNotEmpty ?? false) ||
                    (order.notes?.isNotEmpty ?? false)))
              ...[
                const SizedBox(height: 6),
                if (order.eventDate != null)
                  Text('Event Date: $readableEventDate',
                      style: const TextStyle(fontSize: 16, color: Colors.deepPurple)),
                if (order.customerPhone?.isNotEmpty ?? false)
                  Text('Customer Phone: ${order.customerPhone}',
                      style: const TextStyle(fontSize: 16, color: Colors.deepPurple)),
                if (order.notes?.isNotEmpty ?? false)
                  Text('PIC/Notes: ${order.notes}',
                      style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
              ],
            const SizedBox(height: 4),
            Text('Created: ${DateFormat('yyyy-MM-dd – HH:mm').format(order.time)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Status: ${order.status.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPaid ? Colors.green : Colors.red,
              ),
            ),
            if (isPaid) ...[
              const SizedBox(height: 4),
              Text('Paid At: ${order.paymentTime != null ? DateFormat('yyyy-MM-dd – HH:mm').format(order.paymentTime!) : "-"}'),
              Text('Payment Method: ${order.paymentMethod ?? "-"}'),
            ],
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (_, index) {
                  final item = order.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.name} x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Rp ${item.price.toStringAsFixed(0)}'),
                          if (item.addons.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text('Add-ons:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...item.addons.map((addonName) => Text('- $addonName')),
                          ],
                          const SizedBox(height: 6),
                          Text('Subtotal: Rp ${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Rp ${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isPaid ? null : () => _markAsPaid(context),
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Mark as Paid'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _reorder(context),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Reorder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

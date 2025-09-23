// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';
import '../services/settings/brand_prefs.dart';

// 🔽 single printing entrypoint
import '../services/printer/printer_facade.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  // Future<double?> _askAmountPaid(
  //   BuildContext context,
  //   double defaultAmount,
  // ) async {
  //   final ctrl = TextEditingController(text: defaultAmount.toStringAsFixed(0));
  //   double? paid;
  //   await showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text('Amount Received'),
  //           content: TextField(
  //             controller: ctrl,
  //             keyboardType: TextInputType.number,
  //             decoration: const InputDecoration(labelText: 'Rp'),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 paid = double.tryParse(ctrl.text);
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         ),
  //   );
  //   return paid;
  // } // currently unused

  void _reorder(BuildContext context) {
    final cart = context.read<CartModel>();
    for (var item in order.items) {
      final mainProduct = Product(
        name: item.name,
        price: item.price,
        category: 'Restored',
        isAddon: false,
      );
      final addonProducts =
          item.addons.map((addonName) {
            return Product(
              name: addonName,
              price: 0,
              category: 'Addon',
              isAddon: true,
            );
          }).toList();

      cart.addItem(
        CartItem(
          product: mainProduct,
          quantity: item.quantity,
          addons: addonProducts,
        ),
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Items added to cart')));
    Navigator.pop(context, 'reordered');
  }

  void _markAsPaid(BuildContext context) async {
    final methods = ['Cash', 'QRIS', 'Debit', 'Other'];
    String selected = methods[0];

    // Ask payment method + amount in one dialog
    final amount = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        final amountCtrl = TextEditingController(
          text: order.total.toStringAsFixed(0),
        );
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Settle Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    onChanged: (v) => setState(() => selected = v ?? selected),
                    items:
                        methods
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount Received (Rp)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    final paid = double.tryParse(amountCtrl.text);
                    Navigator.pop(ctx, paid);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (amount == null) return; // cancelled

    if (amount < order.total) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount received is less than total')),
      );
      return;
    }

    // Update order -> PAID, save to Hive
    order.status = 'paid';
    order.paymentMethod = selected;
    order.paymentTime = DateTime.now();
    order.amountReceived = amount;
    order.change = amount - order.total;
    await order.save();

    // Build receipt data from the order and print (real on Android, preview elsewhere)
    final data = PrinterFacade.fromOrder(
      order,
      // mode defaults to ReceiptMode.finalPaid
      paidOverride: amount,
      timeOverride: DateTime.now(),
    );
    final b = await BrandPrefs.getBrand();
    final brand = PrinterBrand(
      name: b.name,
      address: b.address,
      phone: b.phone,
      logoAssetPath: b.logoFile == null ? b.logoAsset : null,
      logoFilePath: b.logoFile,
    );

    if (!context.mounted) return;
    await PrinterFacade.print(
      data: data,
      brand: brand,
      // brand: const PrinterBrand(
      //   name: 'Sekata',
      // ),
      context: context, // show preview when no printer / desktop
    );

    if (context.mounted) Navigator.pop(context, 'updated');
  }

  Future<void> _reprint(BuildContext context) async {
    final data = PrinterFacade.fromOrder(
      order,
      paidOverride:
          (order.amountReceived > 0 ? order.amountReceived : order.total),
      timeOverride: DateTime.now(),
    );


    final b = await BrandPrefs.getBrand();
    final brand = PrinterBrand(
      name: b.name,
      address: b.address,
      phone: b.phone,
      logoAssetPath: b.logoFile == null ? b.logoAsset : null,
      logoFilePath: b.logoFile,
    );

      if (!context.mounted) return;

    await PrinterFacade.print(
      data: data,
      brand: brand,
      context: context,
    );
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
                  backgroundColor:
                      isCatering ? Colors.purple[50] : Colors.green[50],
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
              Text(
                'Table: ${order.tableNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            // Catering specific fields
            if (isCatering &&
                (order.eventDate != null ||
                    (order.customerPhone?.isNotEmpty ?? false) ||
                    (order.notes?.isNotEmpty ?? false))) ...[
              const SizedBox(height: 6),
              if (order.eventDate != null)
                Text(
                  'Event Date: $readableEventDate',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
              if (order.customerPhone?.isNotEmpty ?? false)
                Text(
                  'Customer Phone: ${order.customerPhone}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
              if (order.notes?.isNotEmpty ?? false)
                Text(
                  'PIC/Notes: ${order.notes}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
            const SizedBox(height: 4),
            Text(
              'Created: ${DateFormat('yyyy-MM-dd – HH:mm').format(order.time)}',
              style: const TextStyle(fontSize: 16),
            ),
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
              Text(
                'Paid At: ${order.paymentTime != null ? DateFormat('yyyy-MM-dd – HH:mm').format(order.paymentTime!) : "-"}',
              ),
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
                          Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Rp ${item.price.toStringAsFixed(0)}'),
                          if (item.addons.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Add-ons:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...item.addons.map(
                              (addonName) => Text('- $addonName'),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Subtotal: Rp ${item.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                if (isPaid)
                  ElevatedButton.icon(
                    onPressed: () => _reprint(context),
                    icon: const Icon(Icons.print),
                    label: const Text('Re-Print'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

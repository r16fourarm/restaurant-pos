// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';
import '../services/settings/brand_prefs.dart';
import '../services/settings/print_date_prefs.dart';

// 🔽 single printing entrypoint
import '../services/printer/printer_facade.dart';

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
      final addonProducts = item.addons
          .map((addonName) => Product(
                name: addonName,
                price: 0,
                category: 'Addon',
                isAddon: true,
              ))
          .toList();

      cart.addItem(
        CartItem(
          product: mainProduct,
          quantity: item.quantity,
          addons: addonProducts,
        ),
      );
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Items added to cart')));
    Navigator.pop(context, 'reordered');
  }

  void _markAsPaid(BuildContext context) async {
    final methods = ['Cash', 'QRIS', 'Debit', 'Other'];
    String selected = methods[0];

    final amount = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        final amountCtrl =
            TextEditingController(text: order.total.toStringAsFixed(0));
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
                    items: methods
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
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

    // Update order -> PAID
    order.status = 'paid';
    order.paymentMethod = selected;
    order.paymentTime = DateTime.now();
    order.amountReceived = amount;
    order.change = amount - order.total;
    await order.save();

    // Build receipt and print (real on Android, preview elsewhere)
    final data = PrinterFacade.fromOrder(
      order,
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
      context: context,
    );

    if (context.mounted) Navigator.pop(context, 'updated');
  }

  Future<void> _reprint(BuildContext context) async {
    DateTime? override;
    final enabled = await PrintDatePrefs.isEnabled();
    if (enabled) {
      override = await PrintDatePrefs.getOverride();
      // if (kReleaseMode) override = null; // optional safety
    }

    final data = PrinterFacade.fromOrder(
      order,
      paidOverride:
          (order.amountReceived > 0 ? order.amountReceived : order.total),
      timeOverride: override ?? DateTime.now(),
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
    await PrinterFacade.print(data: data, brand: brand, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == 'paid';
    final isCatering = order.mode == 'catering';

    String? readableEventDate;
    if (order.eventDate != null) {
      readableEventDate = DateFormat('yyyy-MM-dd').format(order.eventDate!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mode badge + orderer
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
              Text('Table: ${order.tableNumber}',
                  style: const TextStyle(fontSize: 16)),

            // Catering specifics
            if (isCatering &&
                (order.eventDate != null ||
                    (order.customerPhone?.isNotEmpty ?? false) ||
                    (order.notes?.isNotEmpty ?? false))) ...[
              const SizedBox(height: 6),
              if (order.eventDate != null)
                Text('Event Date: $readableEventDate',
                    style:
                        const TextStyle(fontSize: 16, color: Colors.deepPurple)),
              if (order.customerPhone?.isNotEmpty ?? false)
                Text('Customer Phone: ${order.customerPhone}',
                    style:
                        const TextStyle(fontSize: 16, color: Colors.deepPurple)),
              if (order.notes?.isNotEmpty ?? false)
                Text('PIC/Notes: ${order.notes}',
                    style: const TextStyle(
                        fontSize: 15, fontStyle: FontStyle.italic)),
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

            // Items
            ...List.generate(order.items.length, (index) {
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
                        const Text('Add-ons:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...item.addons.map((addonName) => Text('- $addonName')),
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
            }),

            const Divider(height: 32),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Total:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Rp ${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 80), // give space above bottom bar
          ],
        ),
      ),

      // —— Responsive bottom actions (never cropped) ——
      bottomNavigationBar: _BottomActions(
        isPaid: isPaid,
        onMarkPaid: () => _markAsPaid(context),
        onReorder: () => _reorder(context),
        onReprint: () => _reprint(context),
      ),
    );
  }
}

// ----------------- Bottom actions -----------------

class _BottomActions extends StatelessWidget {
  final bool isPaid;
  final VoidCallback onMarkPaid, onReorder, onReprint;
  const _BottomActions({
    required this.isPaid,
    required this.onMarkPaid,
    required this.onReorder,
    required this.onReprint,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;

            Widget button({
              required Widget child,
              required VoidCallback onPressed,
              bool outlined = false,
            }) {
              final style = outlined
                  ? OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))
                  : ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48));
              return outlined
                  ? OutlinedButton(onPressed: onPressed, style: style, child: child)
                  : ElevatedButton(onPressed: onPressed, style: style, child: child);
            }

            final markBtn = button(
              onPressed: isPaid ? () {} : onMarkPaid,
              child: const _BtnContent(icon: Icons.attach_money, text: 'Mark as Paid'),
            );

            final reorderBtn = button(
              onPressed: onReorder,
              child: const _BtnContent(icon: Icons.shopping_cart, text: 'Reorder'),
            );

            final reprintBtn = button(
              outlined: true,
              onPressed: onReprint,
              child: const _BtnContent(icon: Icons.print, text: 'Re-Print'),
            );

            // Wide screens: single row, equal widths
            if (!isNarrow) {
              return Row(
                children: [
                  Expanded(child: AbsorbPointer(absorbing: isPaid, child: markBtn)),
                  const SizedBox(width: 8),
                  Expanded(child: reorderBtn),
                  const SizedBox(width: 8),
                  if (isPaid) Expanded(child: reprintBtn),
                ],
              );
            }

            // Narrow screens: wrap across lines
            final children = <Widget>[
              SizedBox(
                width: (constraints.maxWidth - 8) / 2,
                child: AbsorbPointer(absorbing: isPaid, child: markBtn),
              ),
              SizedBox(
                width: (constraints.maxWidth - 8) / 2,
                child: reorderBtn,
              ),
              if (isPaid)
                SizedBox(
                  width: constraints.maxWidth,
                  child: reprintBtn,
                ),
            ];

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

class _BtnContent extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BtnContent({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(''), // placeholder; text provided below
          ),
        ),
      ],
    );
  }
}

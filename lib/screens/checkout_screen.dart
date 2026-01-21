// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../app_mode_provider.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/cart_model.dart';
import '../services/settings/brand_prefs.dart';
import '../services/settings/print_date_prefs.dart';

// Printer facade (the only printing import you need here)
import '../services/printer/printer_facade.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _ordererController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();

  // Payment status
  String _paymentStatus = 'paid'; // 'paid' or 'unpaid'
  String _paymentMethod = 'Cash';
  final TextEditingController _amountReceivedController =
      TextEditingController();
  double _change = 0.0;

  // Catering-specific fields
  DateTime? _eventDate;
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  void _updateChange(double total) {
    final amount = double.tryParse(_amountReceivedController.text) ?? 0.0;
    setState(() => _change = amount - total);
  }

  Future<void> _selectEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 366)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _confirmOrder() async {
    final cart = context.read<CartModel>();
    final orderer = _ordererController.text;
    final total = cart.total;

    // Validate when Pay Now
    double amountReceived = 0.0;
    if (_paymentStatus == 'paid') {
      amountReceived = double.tryParse(_amountReceivedController.text) ?? 0.0;
      if (amountReceived < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amount received is less than total!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Build OrderItems from cart
    final orderItems =
        cart.items.map((item) {
          return OrderItem(
            name: item.product.name,
            price: item.product.price,
            quantity: item.quantity,
            addons: item.addons.map((a) => a.name).toList(),
            addonsPrice: item.addons.fold<double>(
              0.0,
              (sum, a) => sum + a.price,
            ),
          );
        }).toList();

    final appMode = context.read<AppModeProvider>().mode;

    // Catering fields
    DateTime? eventDate;
    String? customerPhone;
    String? notes;
    if (appMode == 'catering') {
      eventDate = _eventDate;
      customerPhone =
          _customerPhoneController.text.isNotEmpty
              ? _customerPhoneController.text
              : null;
      notes = _notesController.text.isNotEmpty ? _notesController.text : null;
    }

    // Prepare receipt data BEFORE we clear the cart
    ReceiptData? receiptData;

    DateTime? override;
    final enabled = await PrintDatePrefs.isEnabled();
    if (enabled) {
      override = await PrintDatePrefs.getOverride();
      // Optional safety: ignore in release builds
      // if (kReleaseMode) override = null;
    }
    if (_paymentStatus == 'paid') {
      final date = override ?? DateTime.now();
      final billNumber = date.millisecondsSinceEpoch.toString();
      receiptData = PrinterFacade.fromCart(
        cart,
        // billNumber: DateTime.now().millisecondsSinceEpoch.toString(),
        billNumber: billNumber,
        table: _tableNumberController.text,
        cashierOrOrderer: orderer,
        paid: amountReceived,
        change: _change,
        time: date,
        // tax: 0, service: 0, // add later if you implement them
      );
    }

    // Save order to Hive
    final newOrder = Order(
      items: orderItems,
      total: total,
      mode: appMode,
      // time: DateTime.now(),
      time: override ?? DateTime.now(),

      orderer: orderer,
      tableNumber:
          _tableNumberController.text.isNotEmpty
              ? _tableNumberController.text
              : null,
      status: _paymentStatus,
      eventDate: eventDate,
      customerPhone: customerPhone,
      notes: notes,
      // paymentTime: DateTime.now(),
      paymentTime: override ?? DateTime.now(),

      paymentMethod: _paymentStatus == 'paid' ? _paymentMethod : null,
      amountReceived: _paymentStatus == 'paid' ? amountReceived : 0.0,
      change: _paymentStatus == 'paid' ? _change : 0.0,
    );

    final box = Hive.box<Order>('orders');
    await box.add(newOrder);

    final b = await BrandPrefs.getBrand();
    final brand = PrinterBrand(
      name: b.name,
      address: b.address,
      phone: b.phone,
      logoFilePath:
          (b.logoFile != null && b.logoFile!.isNotEmpty) ? b.logoFile : null,
      logoAssetPath:
          (b.logoFile == null || b.logoFile!.isEmpty) ? b.logoAsset : null,
    );

    // debugPrint('LOGO LOADED: ${logo != null}, bytes=${logo?.length}');
    debugPrint('brand.logoFilePath=${brand.logoFilePath}');
    debugPrint('brand.logoAssetPath=${brand.logoAssetPath}');

    // Print (real on Android if connected, preview elsewhere)
    if (receiptData != null) {
      if (!mounted) return;
      await PrinterFacade.print(
        data: receiptData,
        brand: brand, // todo: set your brand/address/phone
        context: context, // so preview shows when no printer / desktop
      );
    }

    // Clear cart and show result
    cart.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              _paymentStatus == 'paid' ? 'Order Finalized' : 'Order Saved',
            ),
            content: Text(
              _paymentStatus == 'paid'
                  ? 'Thank you${orderer.isNotEmpty ? ', $orderer' : ''}!\n'
                      'Total: Rp ${total.toStringAsFixed(0)}\n'
                      'Paid: Rp ${amountReceived.toStringAsFixed(0)}\n'
                      'Change: Rp ${_change.toStringAsFixed(0)}'
                  : 'Order saved as UNPAID.\nCustomer can pay later.',
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final appMode = context.watch<AppModeProvider>().mode;
    final total = cart.total;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    title: Text('${item.product.name} x ${item.quantity}'),
                    subtitle:
                        (item.addons.isNotEmpty)
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  item.addons
                                      .map(
                                        (addon) => Text(
                                          '- ${addon.name} (Rp ${addon.price.toStringAsFixed(0)})',
                                        ),
                                      )
                                      .toList(),
                            )
                            : null,
                    trailing: Text('Rp ${item.totalPrice.toStringAsFixed(0)}'),
                  );
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _ordererController,
              decoration: const InputDecoration(
                labelText: 'Orderer / Name (optional)',
              ),
            ),
            const SizedBox(height: 8),
            if (appMode == 'restaurant') ...[
              TextField(
                controller: _tableNumberController,
                decoration: const InputDecoration(
                  labelText: 'Table Number (optional)',
                ),
              ),
            ],
            if (appMode == 'catering') ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectEventDate,
                child: AbsorbPointer(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Event Date (optional)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text:
                          _eventDate != null
                              ? DateFormat('yyyy-MM-dd').format(_eventDate!)
                              : '',
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone (optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'PIC / Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 8),

            // Payment status selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'paid',
                    groupValue: _paymentStatus,
                    onChanged: (val) => setState(() => _paymentStatus = val!),
                    title: const Text('Pay Now'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'unpaid',
                    groupValue: _paymentStatus,
                    onChanged: (val) => setState(() => _paymentStatus = val!),
                    title: const Text('Pay Later'),
                  ),
                ),
              ],
            ),

            // Only show payment fields if "Pay Now" is selected
            if (_paymentStatus == 'paid') ...[
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: "Payment Method"),
                items:
                    ['Cash', 'QRIS', 'EDC', 'Other']
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountReceivedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount Received"),
                onChanged: (_) => _updateChange(total),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Change:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _change >= 0 ? 'Rp ${_change.toStringAsFixed(0)}' : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _change < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'Total: Rp ${cart.total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirmOrder,
              child: Text(
                _paymentStatus == 'paid'
                    ? 'Confirm & Finalize'
                    : 'Save as Unpaid',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../app_mode_provider.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/cart_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _ordererController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();

  // Catering-specific fields
  DateTime? _eventDate;
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Future<void> _selectEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 366)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  void _confirmOrder() async {
    final cart = context.read<CartModel>();
    final orderer = _ordererController.text;

    final orderItems = cart.items.map((item) {
      return OrderItem(
        name: item.product.name,
        price: item.product.price,
        quantity: item.quantity,
        addons: item.addons.map((a) => a.name).toList(),
        addonsPrice:
            item.addons.fold(0.0, (sum, a) => (sum as double) + a.price) ?? 0.0,
      );
    }).toList();

    final total = cart.total;
    final appMode = context.read<AppModeProvider>().mode;

    // Catering fields (only for catering)
    DateTime? eventDate;
    String? customerPhone;
    String? notes;
    if (appMode == 'catering') {
      eventDate = _eventDate;
      customerPhone =
          _customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : null;
      notes = _notesController.text.isNotEmpty ? _notesController.text : null;
    }

    final newOrder = Order(
      items: orderItems,
      total: total,
      mode: appMode,
      time: DateTime.now(),
      orderer: orderer,
      tableNumber: _tableNumberController.text.isNotEmpty
          ? _tableNumberController.text
          : null,
      status: 'unpaid',
      eventDate: eventDate,
      customerPhone: customerPhone,
      notes: notes,
    );

    final box = Hive.box<Order>('orders');
    await box.add(newOrder);

    cart.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Saved'),
        content: Text(
          'Thank you${orderer.isNotEmpty ? ', $orderer' : ''}!\n'
          'Total: Rp ${total.toStringAsFixed(0)}',
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
                    subtitle: (item.addons.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.addons
                                .map((addon) => Text(
                                      '- ${addon.name} (Rp ${addon.price.toStringAsFixed(0)})',
                                    ))
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
                    decoration: InputDecoration(
                      labelText: 'Event Date (optional)',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _eventDate != null
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
            const SizedBox(height: 16),
            Text(
              'Total: Rp ${cart.total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirmOrder,
              child: const Text('Confirm Order'),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/services/printer/printer_facade.dart
import 'dart:io' show Platform, File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import 'bt_receipt_printer.dart';
import 'debug_receipt_printer.dart';
import 'print_receipt.dart'; // ReceiptMode + printRestaurantReceipt
import 'receipt_printer.dart';
import 'escpos_image.dart'; // <-- NEW: ESC/POS raster image helper

// Your models
import '../../models/order.dart';
import '../../models/cart_model.dart';

/// Branding configuration for receipts.
class PrinterBrand {
  final String name;
  final String? address;
  final String? phone;

  /// Choose one: asset path, file path, or raw bytes.
  final String? logoAssetPath;
  final String? logoFilePath;
  final Uint8List? logoBytes;

  const PrinterBrand({
    required this.name,
    this.address,
    this.phone,
    this.logoAssetPath,
    this.logoFilePath,
    this.logoBytes,
  });
}

/// Line item to be printed
class PrintableItem {
  final String name;
  final int qty;
  final num total;
  final List<String> addons;

  const PrintableItem({
    required this.name,
    required this.qty,
    required this.total,
    this.addons = const [],
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'qty': qty,
    'total': total,
    'addons': addons.map((n) => {'name': n}).toList(),
  };
}

/// Encapsulates receipt data
class ReceiptData {
  final ReceiptMode mode;
  final String billNumber;
  final String? table;
  final String cashierOrOrderer;
  final List<PrintableItem> items;
  final double subtotal;
  final double tax;
  final double service;
  final double total;
  final double? paid;
  final double? change;
  final DateTime time;
  final String? footerNote;

  const ReceiptData({
    required this.mode,
    required this.billNumber,
    this.table,
    required this.cashierOrOrderer,
    required this.items,
    required this.subtotal,
    this.tax = 0,
    this.service = 0,
    required this.total,
    this.paid,
    this.change,
    required this.time,
    this.footerNote,
  });

  List<Map<String, dynamic>> toItemsMap() =>
      items.map((i) => i.toMap()).toList();
}

class PrinterFacade {
  static const int _defaultHeadWidthPx = 384;
  static const String _fallbackAsset = 'assets/logo_sekata.png';

  /// Print using BT on Android if connected, else debug preview.
  ///
  /// [logoTargetWidth] is only used on real printers (ESC/POS path).
  /// Keep it <= 384 for 58mm heads; 320 is safest to avoid stalls.
  static Future<void> print({
    required ReceiptData data,
    required PrinterBrand brand,
    BuildContext? context,
    int printerHeadWidthPx = _defaultHeadWidthPx,
    int logoTargetWidth = 320,
    int logoDarknessThreshold = 140,
  }) async {
    final useReal = await _canUseRealPrinter();
    final ReceiptPrinter printer =
        useReal
            ? BtReceiptPrinter(BlueThermalPrinter.instance)
            : DebugReceiptPrinter();

    Uint8List? logoForPreview;

    // --- Print logo ---
    if (useReal) {
      try {
        // Prefer file logo if present; otherwise use asset (or fallback)
        if ((brand.logoFilePath ?? '').isNotEmpty) {
          await EscPosImage.printLogoFromFile(
            printer: BlueThermalPrinter.instance,
            filePath: brand.logoFilePath!,
            targetWidth: logoTargetWidth,
            darknessThreshold: logoDarknessThreshold,
          );
        } else {
          final String? assetToUse = await _chooseAssetLogo(brand);
          if (assetToUse != null) {
            await EscPosImage.printLogoFromAssets(
              printer: BlueThermalPrinter.instance,
              assetPath: assetToUse,
              targetWidth: logoTargetWidth,
              darknessThreshold: logoDarknessThreshold,
            );
          }
        }

        // --- IMPORTANT RESET SEQUENCE ---
        final bt = BlueThermalPrinter.instance;
        await bt.writeBytes(Uint8List.fromList([0x1B, 0x40])); // ESC @
        await bt.writeBytes(Uint8List.fromList([0x1B, 0x74, 0x00])); // ESC t 0
        await bt.writeBytes(Uint8List.fromList([0x0A, 0x0A])); // LF x2
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } catch (_) {
        // continue with text-only if the logo fails
      }
      logoForPreview = null; // don't double-print logo in text renderer
    } else {
      // unchanged: preview supports both file & asset
      logoForPreview = await _loadLogoBytes(
        assetPath: brand.logoAssetPath,
        filePath: brand.logoFilePath,
        bytes: brand.logoBytes,
      );
    }

    // --- Print the rest of the receipt text/lines ---
    await printRestaurantReceipt(
      printer,
      mode: data.mode,
      brand: brand,
      billNumber: data.billNumber,
      table: data.table,
      cashierOrOrderer: data.cashierOrOrderer,
      items: data.toItemsMap(),
      subtotal: data.subtotal,
      tax: data.tax,
      service: data.service,
      total: data.total,
      paid: data.paid,
      change: data.change,
      time: data.time,
      footerNote: data.footerNote,
      // For real printer we already printed the logo above; pass null to skip.
      // For debug preview, pass bytes so the dialog can show the image.
      logoBytes: logoForPreview,
    );

    // --- Debug preview dialog (desktop/no BT) ---
    if (!useReal && context != null && context.mounted) {
      final mock = printer as DebugReceiptPrinter;
      // ignore: use_build_context_synchronously
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(
                data.mode == ReceiptMode.finalPaid
                    ? 'Receipt Preview'
                    : 'UNPAID Ticket Preview',
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (logoForPreview != null &&
                        logoForPreview.isNotEmpty) ...[
                      Center(child: Image.memory(logoForPreview, height: 80)),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      mock.output,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    }
  }

  /// Build ReceiptData from an Order (paid/unpaid)
  static ReceiptData fromOrder(
    Order o, {
    ReceiptMode mode = ReceiptMode.finalPaid,
    double? paidOverride,
    DateTime? timeOverride,
    String? footerNote,
  }) {
    final items =
        o.items
            .map(
              (it) => PrintableItem(
                name: it.name,
                qty: it.quantity,
                total: it.total,
                addons: it.addons,
              ),
            )
            .toList();

    final total = o.total;
    final paid =
        (mode == ReceiptMode.finalPaid)
            ? (paidOverride ??
                (o.amountReceived > 0 ? o.amountReceived : total))
            : null;
    final change =
        (mode == ReceiptMode.finalPaid && paid != null) ? (paid - total) : null;

    return ReceiptData(
      mode: mode,
      billNumber: (o.key ?? o.time.millisecondsSinceEpoch).toString(),
      table: o.tableNumber,
      cashierOrOrderer: (o.orderer.isNotEmpty ? o.orderer : '-'),
      items: items,
      subtotal: total,
      total: total,
      paid: paid,
      change: change,
      time: timeOverride ?? DateTime.now(),
      footerNote: footerNote,
    );
  }

  /// Alias to match any legacy callers using snake_case.
  static ReceiptData fromOrderLegacy(
    Order o, {
    ReceiptMode mode = ReceiptMode.finalPaid,
    double? paidOverride,
    DateTime? timeOverride,
    String? footerNote,
  }) => fromOrder(
    o,
    mode: mode,
    paidOverride: paidOverride,
    timeOverride: timeOverride,
    footerNote: footerNote,
  );

  /// Build ReceiptData from the Cart (checkout “Pay Now”)
  static ReceiptData fromCart(
    CartModel cart, {
    required String billNumber,
    String? table,
    required String cashierOrOrderer,
    double tax = 0,
    double service = 0,
    required double paid,
    required double change,
    DateTime? time,
    String? footerNote,
  }) {
    final items =
        cart.items
            .map(
              (ci) => PrintableItem(
                name: ci.product.name,
                qty: ci.quantity,
                total: ci.totalPrice,
                addons: ci.addons.map((a) => a.name).toList(),
              ),
            )
            .toList();

    final subtotal = cart.total;
    final total = subtotal + tax + service;

    return ReceiptData(
      mode: ReceiptMode.finalPaid,
      billNumber: billNumber,
      table: (table != null && table.isNotEmpty) ? table : null,
      cashierOrOrderer:
          cashierOrOrderer.isNotEmpty ? cashierOrOrderer : 'Cashier',
      items: items,
      subtotal: subtotal,
      tax: tax,
      service: service,
      total: total,
      paid: paid,
      change: change,
      time: time ?? DateTime.now(),
      // time: time ?? DateTime(2025, 08, 27, 19, 30),
      footerNote: footerNote,
    );
  }

  // ---------- internal helpers ----------

  static Future<bool> _canUseRealPrinter() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await BlueThermalPrinter.instance.isConnected) == true;
    } catch (_) {
      return false;
    }
  }

  /// Prefer asset path for ESC/POS printing; otherwise try a fallback asset.
  static Future<String?> _chooseAssetLogo(PrinterBrand brand) async {
    if (brand.logoAssetPath != null && brand.logoAssetPath!.isNotEmpty) {
      return brand.logoAssetPath!;
    }
    // If no asset given, try fallback asset declared in pubspec
    try {
      await rootBundle.load(_fallbackAsset);
      return _fallbackAsset;
    } catch (_) {
      return null;
    }
  }

  /// Load logo bytes from memory/file/asset (used for debug preview only).
  static Future<Uint8List?> _loadLogoBytes({
    String? assetPath,
    String? filePath,
    Uint8List? bytes,
  }) async {
    try {
      if (bytes != null && bytes.isNotEmpty) return bytes;

      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) return await f.readAsBytes();
      }

      if (assetPath != null && assetPath.isNotEmpty) {
        final data = await rootBundle.load(assetPath);
        return data.buffer.asUint8List();
      }

      // fallback asset
      try {
        final data = await rootBundle.load(_fallbackAsset);
        return data.buffer.asUint8List();
      } catch (_) {
        // ignore if fallback asset missing
      }
    } catch (_) {}
    return null;
  }
}

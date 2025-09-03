import 'dart:typed_data';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';

enum AlignX { left, center, right }

/// Optional size levels for text
enum ReceiptTextSize { sm, md, lg }

abstract class ReceiptPrinter {
  Future<bool> isConnected();
  Future<void> println(String text, {int size = 1, int align = 0});
  Future<void> leftRight(String left, String right, {int size = 1});
  Future<void> divider();
  Future<void> newline();
  Future<void> cut();
  Future<void> printImage(Uint8List pngBytes, {AlignX align = AlignX.left});
}

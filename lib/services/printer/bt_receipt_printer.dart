// lib/services/printer/bt_receipt_printer.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'receipt_printer.dart';
import 'dart:typed_data';

class BtReceiptPrinter implements ReceiptPrinter {
  final BlueThermalPrinter _bt;
  BtReceiptPrinter(this._bt);

  Future<void> _safeDelay([int ms = 60]) async =>
      Future<void>.delayed(Duration(milliseconds: ms));

  bool _textModeReady = false;

  Future<void> _ensureTextModeOnce() async {
    if (_textModeReady) return;
    try {
      // ESC @ (initialize)
      await _bt.writeBytes(Uint8List.fromList([0x1B, 0x40]));
      // ESC t 0 (code page PC437) – optional but stabilizes some printers
      await _bt.writeBytes(Uint8List.fromList([0x1B, 0x74, 0x00]));
      // One LF to flush any pending raster
      await _bt.writeBytes(Uint8List.fromList([0x0A]));
      await _safeDelay(120);
    } catch (_) {
      // keep going even if the plugin/printer ignores these
    }
    _textModeReady = true;
  }

  @override
  Future<bool> isConnected() async => (await _bt.isConnected) == true;

  @override
  Future<void> println(String text, {int size = 1, int align = 0}) async {
    await _ensureTextModeOnce();
    await _bt.printCustom(text, size, align);
    // await _bt.printNewLine();
    await _safeDelay();
  }

  @override
  Future<void> leftRight(String left, String right, {int size = 1}) async {
    await _ensureTextModeOnce();
    await _bt.printLeftRight(left, right, size);
    // await _bt.printNewLine();
    await _safeDelay();
  }

  @override
  Future<void> divider() async {
    await _ensureTextModeOnce();
    await _bt.printCustom('-' * 32, 1, 1);
    await _bt.printNewLine();
    await _safeDelay();
  }

  @override
  Future<void> newline() async {
    await _ensureTextModeOnce();
    await _bt.printNewLine();
    await _safeDelay(40);
  }

  @override
  Future<void> cut() async {
    await _ensureTextModeOnce();
    try {
      await _bt.paperCut();
    } catch (_) {
      // Fallback: feed a few lines
      await _bt.printNewLine();
      await _bt.printNewLine();
      await _bt.printNewLine();
    }
  }

  @override
  Future<void> printImage(
    Uint8List pngBytes, {
    AlignX align = AlignX.left,
  }) async {
    // Used mainly in debug/preview; real logo printing uses ESC/POS in facade.
    try {
      await _bt.printImageBytes(pngBytes);
      await _bt.printNewLine();
      _textModeReady = false; // force re-init before next text
      await _safeDelay(120);
    } catch (_) {
      // ignore if not supported
    }
  }

  // Optional: raw write for quick probes
  Future<void> writeRaw(List<int> bytes) async {
    await _bt.writeBytes(Uint8List.fromList(bytes));
    await _safeDelay(40);
  }
}

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'receipt_printer.dart';

class BtReceiptPrinter implements ReceiptPrinter {
  final BlueThermalPrinter bt;
  BtReceiptPrinter(this.bt);

  @override
  Future<bool> isConnected() async => (await bt.isConnected) ?? false;

  @override
  Future<void> println(String text, {int size = 1, int align = 0}) async =>
      bt.printCustom(text, size, align);

  @override
  Future<void> leftRight(String left, String right, {int size = 1}) async =>
      bt.printLeftRight(left, right, size);

  @override
  Future<void> divider() async => bt.printCustom('-' * 32, 1, 1);

  @override
  Future<void> newline() async => bt.printNewLine();

  @override
  Future<void> cut() async => bt.paperCut();
}

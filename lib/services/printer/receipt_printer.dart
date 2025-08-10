abstract class ReceiptPrinter {
  Future<bool> isConnected();
  Future<void> println(String text, {int size = 1, int align = 0});
  Future<void> leftRight(String left, String right, {int size = 1});
  Future<void> divider();
  Future<void> newline();
  Future<void> cut();
}

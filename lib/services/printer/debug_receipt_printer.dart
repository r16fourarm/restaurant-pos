import 'dart:math';
import 'receipt_printer.dart';

class DebugReceiptPrinter implements ReceiptPrinter {
  final StringBuffer _buf = StringBuffer();
  static const int width = 32; // typical 58mm line width

  @override Future<bool> isConnected() async => true;

  @override Future<void> println(String t,{int size=1,int align=0}) async {
    _buf.writeln(t);
  }

  @override Future<void> leftRight(String l,String r,{int size=1}) async {
    final spaces = max(1, width - (l.length + r.length));
    _buf.writeln('$l${' ' * spaces}$r');
  }

  @override Future<void> divider() async => _buf.writeln('-' * width);
  @override Future<void> newline() async => _buf.writeln('');
  @override Future<void> cut() async => _buf.writeln('[[CUT]]');

  String get output => _buf.toString();
}

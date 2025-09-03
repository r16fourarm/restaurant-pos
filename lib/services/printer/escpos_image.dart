// lib/services/printer/escpos_image.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'dart:io' as io;

/// ESC/POS image utilities for 58mm printers (384 px head).
/// Works with image: ^4.5.4
class EscPosImage {
  static const int kMaxWidth58mm = 384;


    static Future<void> printLogoFromFile({
    required BlueThermalPrinter printer,
    required String filePath,
    int targetWidth = 320,
    int darknessThreshold = 128,
    int writeChunk = 1024,
    int interChunkDelayMs = 20,
  }) async {
    final connected = await printer.isConnected == true;
    if (!connected) throw Exception('Printer not connected.');

    final bytes = await io.File(filePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Failed to decode file logo');

    // --- same pipeline as your assets version ---
    final safeWidth = targetWidth.clamp(8, kMaxWidth58mm);
    final scaled = img.copyResize(decoded,
        width: safeWidth, interpolation: img.Interpolation.cubic);

    // center on 384px white canvas (4.5.4: use compositeImage)
    final fullWidth = kMaxWidth58mm;
    final padLeft = ((fullWidth - scaled.width) / 2).floor().clamp(0, fullWidth);
    final padded = img.Image(width: fullWidth, height: scaled.height);
    img.fill(padded, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(padded, scaled, dstX: padLeft, dstY: 0);

    final gray = img.grayscale(padded);
    final dithered = img.ditherImage(gray);

    // binarize
    final w = dithered.width, h = dithered.height;
    final bw = List<bool>.filled(w * h, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final lum = img.getLuminance(dithered.getPixel(x, y));
        bw[y * w + x] = lum < darknessThreshold;
      }
    }

    // GS v 0 encode
    final bytesPerRow = (w + 7) >> 3;
    final out = BytesBuilder()
      ..add([0x1D, 0x76, 0x30, 0x00])
      ..add([bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF])
      ..add([h & 0xFF, (h >> 8) & 0xFF]);
    for (int y = 0; y < h; y++) {
      final row = y * w;
      for (int b = 0; b < bytesPerRow; b++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = b * 8 + bit;
          final black = (x < w) ? bw[row + x] : false;
          if (black) byte |= (0x80 >> bit);
        }
        out.addByte(byte);
      }
    }

    // chunked write
    final raster = out.toBytes();
    for (int i = 0; i < raster.length; i += writeChunk) {
      final end = (i + writeChunk < raster.length) ? i + writeChunk : raster.length;
      await printer.writeBytes(raster.sublist(i, end));
      if (interChunkDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: interChunkDelayMs));
      }
    }

    // small feed
    await printer.writeBytes(Uint8List.fromList([0x0A, 0x0A]));
  }

  /// Load an image asset, center it on a 384px canvas, and print via GS v 0.
  static Future<void> printLogoFromAssets({
    required BlueThermalPrinter printer,
    required String assetPath,
    int targetWidth = 320,       // logo width inside 384 canvas
    int darknessThreshold = 128, // 0..255 (lower = darker)
    int writeChunk = 1024,
    int interChunkDelayMs = 20,
  }) async {
    final connected = await printer.isConnected == true;
    if (!connected) {
      throw Exception('Printer not connected.');
    }

    // 1) Load & decode
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('Failed to decode image: $assetPath');
    }

    // 2) Resize to safe width (keep aspect)
    final safeWidth = targetWidth.clamp(8, kMaxWidth58mm);
    final scaled = img.copyResize(
      original,
      width: safeWidth,
      interpolation: img.Interpolation.cubic,
    );

    // 3) Center on full 384-px canvas (white background)
    final fullWidth = kMaxWidth58mm;
    final padLeft = ((fullWidth - scaled.width) / 2).floor().clamp(0, fullWidth);
    final padded = img.Image(width: fullWidth, height: scaled.height);
    img.fill(padded, color: img.ColorRgb8(255, 255, 255)); // white
    img.compositeImage(
      padded,
      scaled,
      dstX: padLeft,
      dstY: 0,
    );

    // 4) Grayscale + Floyd–Steinberg dither, then binarize
    final gray = img.grayscale(padded);
    final dithered = img.ditherImage(gray);
    final bwMask = _binarize(dithered, threshold: darknessThreshold);

    // 5) Encode GS v 0 raster
    final raster = _encodeGsv0(bwMask, dithered.width, dithered.height);

    // 6) Send in chunks
    for (int i = 0; i < raster.length; i += writeChunk) {
      final end = (i + writeChunk < raster.length) ? i + writeChunk : raster.length;
      await printer.writeBytes(raster.sublist(i, end));
      if (interChunkDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: interChunkDelayMs));
      }
    }

    // 7) Nudge paper a bit
    await printer.writeBytes(Uint8List.fromList([0x0A, 0x0A]));
  }

  /// Luminance threshold → boolean mask (true = black dot)
  static List<bool> _binarize(img.Image im, {int threshold = 128}) {
    final w = im.width, h = im.height;
    final out = List<bool>.filled(w * h, false, growable: false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final c = im.getPixel(x, y);           // color
        final lum = img.getLuminance(c);       // 0..255
        out[y * w + x] = lum < threshold;      // black if below threshold
      }
    }
    return out;
  }

  /// ESC/POS Raster Bit Image (GS v 0) encoder
  /// 1D 76 30 m xL xH yL yH [data], m=0
  static Uint8List _encodeGsv0(List<bool> bw, int width, int height) {
    final bytesPerRow = (width + 7) >> 3;
    final out = BytesBuilder();

    // Header
    out.add([0x1D, 0x76, 0x30, 0x00]);
    out.add([bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF]); // xL, xH
    out.add([height & 0xFF, (height >> 8) & 0xFF]);           // yL, yH

    // Pack pixels MSB→LSB
    for (int y = 0; y < height; y++) {
      final row = y * width;
      for (int b = 0; b < bytesPerRow; b++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = b * 8 + bit;
          final black = (x < width) ? bw[row + x] : false;
          if (black) byte |= (0x80 >> bit);
        }
        out.addByte(byte);
      }
    }
    return out.toBytes();
  }
}

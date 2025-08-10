import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensurePrinterPermissions() async {
  if (!Platform.isAndroid) return true;

  // Try requesting the permissions we may need.
  // On older Android versions, some of these are no-ops—catch and ignore.
  final results = <bool>[];

  Future<bool> ask(Permission p) async {
    try {
      final status = await p.request();
      return status.isGranted || status.isLimited; // limited = iOS nuance
    } catch (_) {
      return true; // treat as OK if not applicable on this OS
    }
  }

  // Android 12+ needs bluetoothScan/connect; older Androids need location for discovery.
  results.add(await ask(Permission.locationWhenInUse));
  results.add(await ask(Permission.bluetoothScan));
  results.add(await ask(Permission.bluetoothConnect));

  // If you also use classic discovery/bonding, you can optionally request:
  // results.add(await ask(Permission.bluetooth));

  // All requested permissions should be granted (or N/A)
  return results.every((ok) => ok);
}

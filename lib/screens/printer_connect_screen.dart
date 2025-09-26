import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/printer/printer_permission.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PrinterConnectScreen extends StatefulWidget {
  const PrinterConnectScreen({super.key});

  @override
  State<PrinterConnectScreen> createState() => _PrinterConnectScreenState();
}

class _PrinterConnectScreenState extends State<PrinterConnectScreen> {
  final BlueThermalPrinter bt = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  bool loading = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();

    // Guard: only touch the plugin on Android
    if (!_isAndroid) return;

    // Ask permissions, then refresh the bonded devices list
    Future.microtask(() async {
      final ok = await ensurePrinterPermissions();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permission denied')),
        );
        return;
      }
      await _refresh();
    });
  }

  Future<void> _refresh() async {
    if (!_isAndroid) return; // extra safety
    setState(() => loading = true);
    try {
      devices = await bt.getBondedDevices();
    } catch (_) {
      devices = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _connect(BluetoothDevice d) async {
    if (!_isAndroid) return;
    setState(() => loading = true);
    try {
      await bt.connect(d);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${d.name ?? d.address}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connect failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _disconnect() async {
    if (!_isAndroid) return;
    try {
      await bt.disconnect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // UI guard: show message on non-Android, don’t call plugin APIs
    if (!_isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connect Printer')),
        body: const Center(
          child: Text(
            'Bluetooth thermal printer is only available on Android.\n'
            'Use the Preview receipt on desktop.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Printer'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? const Center(child: Text('No bonded devices.\nPair in system Bluetooth first.'))
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (_, i) {
                    final d = devices[i];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(d.name ?? d.address ?? 'Unknown'),
                      subtitle: Text(d.address ?? ''),
                      trailing: FutureBuilder<bool?>(
                        future: bt.isConnected,
                        builder: (_, snap) {
                          final isConn = snap.data == true;
                          return isConn
                              ? TextButton(onPressed: _disconnect, child: const Text('Disconnect'))
                              : TextButton(onPressed: () => _connect(d), child: const Text('Connect'));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}


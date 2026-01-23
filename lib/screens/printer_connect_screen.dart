import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../services/printer/printer_permission.dart';

class PrinterConnectScreen extends StatefulWidget {
  const PrinterConnectScreen({super.key});

  @override
  State<PrinterConnectScreen> createState() => _PrinterConnectScreenState();
}

class _PrinterConnectScreenState extends State<PrinterConnectScreen> {
  final BlueThermalPrinter _bt = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  bool _loading = false;

  // Simple local connection cache so we don't rebuild with lots of FutureBuilders
  bool _connected = false;
  String? _connectedAddr; // best-effort: we set this on connect

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      // Ask permissions & bootstrap
      Future.microtask(() async {
        final ok = await ensurePrinterPermissions();
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth permission denied')),
          );
          return;
        }
        await _refreshAll();
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshDevices(), _refreshConn()]);
  }

  Future<void> _refreshConn() async {
    if (!_isAndroid) return;
    try {
      final c = await _bt.isConnected ?? false;
      if (!mounted) return;
      setState(() => _connected = c);
    } catch (_) {
      if (!mounted) return;
      setState(() => _connected = false);
    }
  }

  Future<void> _refreshDevices() async {
    if (!_isAndroid) return;
    setState(() => _loading = true);
    try {
      final list = await _bt.getBondedDevices();
      if (!mounted) return;
      setState(() => _devices = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _devices = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect(BluetoothDevice d) async {
    if (!_isAndroid) return;
    setState(() => _loading = true);
    try {
      await _bt.connect(d);
      _connectedAddr = d.address; // remember what we connected to
      if (!mounted) return;
      await _refreshConn();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${d.name ?? d.address}')),
      );
      
      // Tell caller (e.g., Drawer) that connection state changed
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connect failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    if (!_isAndroid) return;
    setState(() => _loading = true);
    try {
      await _bt.disconnect();
      _connectedAddr = null;
      if (!mounted) return;
      await _refreshConn();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected')),
      );
      // Pop with result so the previous screen can refresh its UI/state
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnect error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Non-Android guard
    if (!_isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connect Printer')),
        body: const Center(
          child: Text(
            'Bluetooth thermal printer is only available on Android.\n'
            'Use the receipt preview on desktop.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh devices',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? const Center(
                  child: Text(
                    'No bonded devices.\nPair the printer in system Bluetooth first.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = _devices[i];
                      final isThisConnected =
                          _connected && (d.address == _connectedAddr || _connectedAddr == null);
                      // If plugin can’t tell us which device is connected, we still show a single Disconnect when any is connected.
                      return ListTile(
                        leading: Icon(
                          Icons.print,
                          color: isThisConnected ? Colors.green : null,
                        ),
                        title: Text(d.name ?? d.address ?? 'Unknown'),
                        subtitle: Text(
                          [
                            if (d.address != null) d.address!,
                            if (isThisConnected) 'Connected',
                          ].join('  ·  '),
                        ),
                        trailing: _connected && isThisConnected
                            ? TextButton(
                                onPressed: _disconnect,
                                child: const Text('Disconnect'),
                              )
                            : TextButton(
                                onPressed: () => _connect(d),
                                child: const Text('Connect'),
                              ),
                        onTap: () => _connect(d),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: _connected
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Disconnect'),
                  onPressed: _disconnect,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            )
          : null,
    );
  }
}

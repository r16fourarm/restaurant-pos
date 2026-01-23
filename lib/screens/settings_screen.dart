import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../services/settings/brand_prefs.dart';
import '../services/settings/print_date_prefs.dart';

// receipt style prefs + types
import '../services/printer/receipt_prefs.dart';
import '../services/printer/print_receipt.dart';

// For test print
import '../services/printer/printer_facade.dart'
    show PrinterFacade, PrinterBrand, ReceiptData, PrintableItem;
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _phoneCtrl;

  String? _logoAsset;
  String? _logoFile;

  bool _customDateEnabled = false;
  DateTime? _customDate;

  ReceiptStyle _receiptStyle = ReceiptStyle.standard;
  bool _loadingStyle = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addrCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    // kick off async loads
    _loadBrand();
    _loadPrintDatePrefs();
    _loadReceiptStyle();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBrand() async {
    final b = await BrandPrefs.getBrand();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = b.name;
      _addrCtrl.text = b.address;
      _phoneCtrl.text = b.phone;
      _logoAsset = b.logoAsset;
      _logoFile = b.logoFile;
    });
  }

  Future<void> _loadReceiptStyle() async {
    final s = await ReceiptPrefs.get();
    if (!mounted) return;
    setState(() {
      _receiptStyle = s;
      _loadingStyle = false;
    });
  }

  Future<void> _saveReceiptStyle(ReceiptStyle s) async {
    // Update UI first (snappy UX)
    setState(() => _receiptStyle = s);

    await ReceiptPrefs.set(s);

    // IMPORTANT: don't use context if widget unmounted after await
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt style saved')),
    );
  }

  Future<void> _loadPrintDatePrefs() async {
    final en = await PrintDatePrefs.isEnabled();
    final dt = await PrintDatePrefs.getOverride();
    if (!mounted) return;
    setState(() {
      _customDateEnabled = en;
      _customDate = dt;
    });
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (d == null) return;
    if (!mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: _customDate != null
          ? TimeOfDay(hour: _customDate!.hour, minute: _customDate!.minute)
          : TimeOfDay.fromDateTime(now),
    );
    if (t == null) return;
    if (!mounted) return;

    final chosen = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    await PrintDatePrefs.setOverride(chosen);
    if (!mounted) return;

    setState(() => _customDate = chosen);
  }

  Widget _customDateSection() {
    final fmt = (_customDate == null)
        ? '—'
        : DateFormat('dd/MM/yyyy HH:mm').format(_customDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Test Print Date',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text('Enable custom print date (testing)'),
          value: _customDateEnabled,
          onChanged: (v) async {
            await PrintDatePrefs.setEnabled(v);
            if (!mounted) return;
            setState(() => _customDateEnabled = v);
          },
        ),
        ListTile(
          title: const Text('Custom date/time'),
          subtitle: Text(fmt),
          trailing: ElevatedButton(
            onPressed: _customDateEnabled ? _pickCustomDateTime : null,
            child: const Text('Set'),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _customDateEnabled && _customDate != null
                ? () async {
                    await PrintDatePrefs.clearOverride();
                    if (!mounted) return;
                    setState(() => _customDate = null);
                  }
                : null,
            child: const Text('Clear date'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final saved = await BrandPrefs.setLogoFromFile(path);
    if (saved == null) return;

    // Reload brand info from prefs after save
    await _loadBrand();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo updated')),
    );
  }

  Future<void> _resetLogo() async {
    await BrandPrefs.resetLogoToAsset();
    await _loadBrand();
    // No context usage here; safe.
  }

  Future<void> _saveBrand() async {
    await BrandPrefs.setBrand(
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brand saved')),
    );
  }

  // -------- Receipt Style Toggle + Test Print --------

  Widget _receiptStyleSection(BuildContext context) {
    if (_loadingStyle) {
      return const ListTile(
        title: Text('Receipt Style'),
        subtitle: Text('Loading...'),
      );
    }

    final useSegmented = Theme.of(context).useMaterial3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Receipt Style',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (useSegmented)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SegmentedButton<ReceiptStyle>(
              segments: const [
                ButtonSegment(
                  value: ReceiptStyle.standard,
                  label: Text('Standard'),
                  icon: Icon(Icons.image),
                ),
                ButtonSegment(
                  value: ReceiptStyle.simpleText,
                  label: Text('Text-only'),
                  icon: Icon(Icons.notes),
                ),
                ButtonSegment(
                  value: ReceiptStyle.blankNote,
                  label: Text('Blank'),
                  icon: Icon(Icons.receipt_long),
                ),
              ],
              selected: <ReceiptStyle>{_receiptStyle},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _saveReceiptStyle(s.first),
            ),
          )
        else
          Column(
            children: [
              RadioListTile<ReceiptStyle>(
                title: const Text('Standard (with logo/brand)'),
                value: ReceiptStyle.standard,
                groupValue: _receiptStyle,
                onChanged: (v) => v == null ? null : _saveReceiptStyle(v),
              ),
              RadioListTile<ReceiptStyle>(
                title: const Text('Text-only (brand header)'),
                value: ReceiptStyle.simpleText,
                groupValue: _receiptStyle,
                onChanged: (v) => v == null ? null : _saveReceiptStyle(v),
              ),
              RadioListTile<ReceiptStyle>(
                title: const Text('Blank note (date + items + totals)'),
                value: ReceiptStyle.blankNote,
                groupValue: _receiptStyle,
                onChanged: (v) => v == null ? null : _saveReceiptStyle(v),
              ),
            ],
          ),

        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Test Print'),
            onPressed: _onTestPrintPressed,
          ),
        ),
      ],
    );
  }

  Future<void> _onTestPrintPressed() async {
    // Load brand for test
    final b = await BrandPrefs.getBrand();

    // If user navigated away while loading prefs, stop.
    if (!mounted) return;

    final brand = PrinterBrand(
      name: b.name,
      address: b.address,
      phone: b.phone,
      logoAssetPath: b.logoAsset,
      logoFilePath: b.logoFile,
      logoBytes: null,
    );

    // Date override (if enabled)
    DateTime when = DateTime.now();
    if (_customDateEnabled) {
      final o = await PrintDatePrefs.getOverride();
      if (!mounted) return;
      if (o != null) when = o;
    }

    // Minimal dummy data for test
    final items = <PrintableItem>[
      const PrintableItem(
        name: 'Nasi Goreng Spesial',
        qty: 1,
        total: 28000,
        addons: ['Telur', 'Kerupuk'],
      ),
      const PrintableItem(
        name: 'Teh Manis Dingin',
        qty: 2,
        total: 12000,
      ),
    ];

    final subtotal = items.fold<num>(0, (s, it) => s + it.total).toDouble();
    final total = subtotal;

    final data = ReceiptData(
      mode: ReceiptMode.finalPaid,
      billNumber: 'TEST-${DateFormat('yyyyMMddHHmmss').format(when)}',
      table: 'A1',
      cashierOrOrderer: 'Tester',
      items: items,
      subtotal: subtotal,
      tax: 0,
      service: 0,
      total: total,
      paid: total,
      change: 0,
      time: when,
      footerNote: 'Settings → Test Print',
    );

    // NOTE:
    // Keeping `context` parameter to avoid refactoring PrinterFacade signature.
    // Ensure PrinterFacade itself uses context safely (checks mounted or avoids UI after awaits).
    await PrinterFacade.print(
      data: data,
      brand: brand,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = _logoFile ?? _logoAsset;

    return Scaffold(
      appBar: AppBar(title: const Text('Brand & Printing')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // BRAND INFO
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _addrCtrl,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 16),

          if (logoPath != null) ...[
            const Text('Current Logo:'),
            const SizedBox(height: 8),
            logoPath.startsWith('assets/')
                ? Image.asset(logoPath, height: 100)
                : Image.file(File(logoPath), height: 100),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image),
                label: const Text('Change Logo'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _resetLogo,
                child: const Text('Use Default'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveBrand,
            child: const Text('Save Brand Info'),
          ),

          // RECEIPT STYLE + TEST PRINT
          _receiptStyleSection(context),

          // CUSTOM DATE (testing)
          _customDateSection(),
        ],
      ),
    );
  }
}

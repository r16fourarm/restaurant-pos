import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings/brand_prefs.dart';
import '../services/settings/print_date_prefs.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addrCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _load();
    _loadPrintDatePrefs(); 
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await BrandPrefs.getBrand();
    setState(() {
      _nameCtrl.text = b.name;
      _addrCtrl.text = b.address;
      _phoneCtrl.text = b.phone;
      _logoAsset = b.logoAsset;
      _logoFile = b.logoFile;
    });
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
    final t = await showTimePicker(
      context: context,
      initialTime:
          _customDate != null
              ? TimeOfDay(hour: _customDate!.hour, minute: _customDate!.minute)
              : TimeOfDay.fromDateTime(now),
    );
    if (t == null) return;
    final chosen = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    await PrintDatePrefs.setOverride(chosen);
    if (!mounted) return;
    setState(() => _customDate = chosen);
  }

  Widget _customDateSection() {
    final fmt =
        (_customDate == null)
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
            onPressed:
                _customDateEnabled && _customDate != null
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
    if (saved != null) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logo updated')));
      }
    }
  }

  Future<void> _resetLogo() async {
    await BrandPrefs.resetLogoToAsset();
    await _load();
  }

  Future<void> _saveBrand() async {
    await BrandPrefs.setBrand(
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Brand saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = _logoFile ?? _logoAsset;

    return Scaffold(
      appBar: AppBar(title: const Text('Brand & Logo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
        _customDateSection(),
        ],
      ),
    );
  }
}

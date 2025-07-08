import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver_model.dart';
import '../providers/driver_notifier.dart';
import '../models/airport_model.dart';
import '../providers/airport_notifier.dart';

class DriverScreen extends ConsumerStatefulWidget {
  static const routeName = '/drivers';
  const DriverScreen({super.key});

  @override
  ConsumerState<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends ConsumerState<DriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuidCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  /// Controllers for each airport’s commission rate
  final Map<String, TextEditingController> _commissionCtrls = {};

  /// Local map of airportId → rate
  Map<String, double> _commissionRates = {};

  Driver? _editing;
  Color? _selectedColor; // ← new

  // a simple palette excluding red/green/orange:
  static const List<Color> _palette = [
    Colors.blue,
    Colors.teal,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void dispose() {
    for (final c in [
      _uuidCtrl, _nameCtrl, _emailCtrl, _phoneCtrl, _whatsappCtrl
    ]) {
      c.dispose();
    }
    for (final ctl in _commissionCtrls.values) {
      ctl.dispose();
    }
    super.dispose();
  }

  void _startEdit(Driver d) {
    _editing = d;
    _uuidCtrl.text     = d.uuid;
    _nameCtrl.text     = d.name;
    _emailCtrl.text    = d.email;
    _phoneCtrl.text    = d.phone;
    _whatsappCtrl.text = d.whatsapp;

    _commissionRates = Map.from(d.commissionRates);

    // Clear out old controllers
    for (final ctl in _commissionCtrls.values) {
      ctl.dispose();
    }
    _commissionCtrls.clear();

    // Seed controllers with existing rates
    d.commissionRates.forEach((airportId, rate) {
      _commissionCtrls[airportId] =
          TextEditingController(text: rate.toString());
    });

    // load the saved color
    _selectedColor = Color(d.colorValue);

    setState(() {});
  }

  void _cancelEdit() {
    _editing = null;
    _uuidCtrl.clear();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _whatsappCtrl.clear();
    _commissionRates.clear();
    _selectedColor = null;

    for (final ctl in _commissionCtrls.values) {
      ctl.dispose();
    }
    _commissionCtrls.clear();

    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a driver color')),
      );
      return;
    }

    final driver = Driver(
      id: _editing?.id ?? '',
      uuid: _uuidCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim(),
      commissionRates: _commissionRates,
      colorValue: _selectedColor!.value, // ← new
    );
    final notifier = ref.read(driverNotifierProvider.notifier);

    try {
      if (_editing == null) {
        await notifier.addDriver(driver);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Driver added')));
      } else {
        await notifier.updateDriver(driver);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Driver updated')));
      }
      _cancelEdit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(Driver d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Driver?'),
        content: Text('Really delete "${d.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(driverNotifierProvider.notifier).deleteDriver(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Driver deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync  = ref.watch(driversStreamProvider);
    final airportsAsync = ref.watch(airportsStreamProvider);
    final isBusy        = ref.watch(driverNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Drivers')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // --- Existing drivers ---
          Expanded(
            child: driversAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No drivers yet.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final d = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(d.colorValue), // show color
                      ),
                      title: Text(d.name),
                      subtitle: Text(d.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit),
                              onPressed: () => _startEdit(d)),
                          IconButton(icon: const Icon(Icons.delete),
                              onPressed: () => _delete(d)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          const Divider(height: 32),

          // --- Add / Edit form ---
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(children: [
                // UUID, Name, Email, Phone, WhatsApp...
                TextFormField(
                  controller: _uuidCtrl,
                  decoration: const InputDecoration(labelText: 'UUID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _whatsappCtrl,
                  decoration: const InputDecoration(labelText: 'WhatsApp'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // --- Color picker ---
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose driver color',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _palette.map((c) {
                    final isSelected = _selectedColor?.value == c.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(width: 3, color: Colors.black)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedColor == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Please pick a color',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                const SizedBox(height: 16),

                // --- Commission rates per airport ---
                airportsAsync.when(
                  data: (airports) {
                    for (final a in airports) {
                      _commissionCtrls.putIfAbsent(
                        a.id,
                            () => TextEditingController(
                          text: _commissionRates[a.id]?.toString() ?? '',
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: airports.map((a) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextFormField(
                            controller: _commissionCtrls[a.id],
                            decoration: InputDecoration(
                              labelText: 'Rate @ ${a.code}',
                            ),
                            keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter rate';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                            onChanged: (v) {
                              _commissionRates[a.id] = double.tryParse(v) ?? 0.0;
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading airports: $e'),
                ),

                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isBusy) ? null : _submit,
                      child: Text(_editing == null ? 'Add Driver' : 'Update Driver'),
                    ),
                  ),
                  if (_editing != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        child: const Text('Cancel'),
                      ),
                    ),
                  ]
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

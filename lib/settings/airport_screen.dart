import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/airport_model.dart';
import '../providers/airport_notifier.dart';

class AirportScreen extends ConsumerStatefulWidget {
  static const routeName = '/airport';
  const AirportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AirportScreen> createState() => _AirportScreenState();
}

class _AirportScreenState extends ConsumerState<AirportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _minsCtrl = TextEditingController();

  Airport? _editing;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _codeCtrl, _costCtrl, _hoursCtrl, _minsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEdit(Airport airport) {
    final offset = airport.pickupOffsetMinutes;
    final hours = offset ~/ 60;
    final mins = offset % 60;

    setState(() {
      _editing = airport;
      _nameCtrl.text = airport.name;
      _codeCtrl.text = airport.code;
      _costCtrl.text = airport.cost.toStringAsFixed(2);
      _hoursCtrl.text = hours.toString();
      _minsCtrl.text = mins.toString();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _nameCtrl.clear();
      _codeCtrl.clear();
      _costCtrl.clear();
      _hoursCtrl.clear();
      _minsCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final cost = double.parse(_costCtrl.text.trim());
    final hours = int.parse(_hoursCtrl.text.trim());
    final mins = int.parse(_minsCtrl.text.trim());
    final offsetMin = hours * 60 + mins;

    final notifier = ref.read(airportNotifierProvider.notifier);
    try {
      if (_editing == null) {
        await notifier.addAirport(name, code, cost, offsetMin);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Airport added')));
      } else {
        await notifier.updateAirport(
            _editing!.id, name, code, cost, offsetMin);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Airport updated')));
      }
      _cancelEdit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(Airport airport) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Airport?'),
        content: Text('Really delete "${airport.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(airportNotifierProvider.notifier).deleteAirport(airport.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Airport deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final airportsAsync = ref.watch(airportsStreamProvider);
    final isBusy = ref.watch(airportNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Airports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // existing airports
            Expanded(
              child: airportsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text('No airports yet.'));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final a = list[i];
                      final h = a.pickupOffsetMinutes ~/ 60;
                      final m = a.pickupOffsetMinutes % 60;
                      return ListTile(
                        title: Text(a.name),
                        subtitle: Text(
                          '${a.code} — £${a.cost.toStringAsFixed(2)}, '
                              'Offset: ${h}h ${m}m',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEdit(a)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(a)),
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

            // add/edit form
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // name / code / cost
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Airport Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(labelText: 'Airport Code'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter a code' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _costCtrl,
                      decoration: const InputDecoration(labelText: 'Cost'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter cost';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // offset hours & minutes
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hoursCtrl,
                            decoration: const InputDecoration(labelText: 'Offset Hours'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter hours';
                              if (int.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _minsCtrl,
                            decoration: const InputDecoration(labelText: 'Offset Minutes'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter minutes';
                              final m = int.tryParse(v);
                              if (m == null || m < 0 || m > 59) return '0–59';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isBusy ? null : _submit,
                            child: Text(_editing == null ? 'Add Airport' : 'Update Airport'),
                          ),
                        ),
                        if (_editing != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(onPressed: _cancelEdit, child: const Text('Cancel')),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

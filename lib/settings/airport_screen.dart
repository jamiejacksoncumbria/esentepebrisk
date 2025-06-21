import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/airport_model.dart';
import '../providers/airport_notifier.dart';

class AirportScreen extends ConsumerStatefulWidget {
  const AirportScreen({super.key});

  static const routeName = '/airport';

  @override
  AirportScreenState createState() => AirportScreenState();
}

class AirportScreenState extends ConsumerState<AirportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  Airport? _editing;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Airport airport) {
    setState(() {
      _editing = airport;
      _nameCtrl.text = airport.name;
      _codeCtrl.text = airport.code;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _nameCtrl.clear();
      _codeCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final notifier = ref.read(airportNotifierProvider.notifier);

    try {
      if (_editing == null) {
        await notifier.addAirport(name, code);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Airport added')));
      } else {
        await notifier.updateAirport(_editing!.id, name, code);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Airport updated')));
        _cancelEdit();
      }
      _nameCtrl.clear();
      _codeCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(Airport airport) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Airport?'),
        content: Text('Really delete "${airport.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(airportNotifierProvider.notifier)
            .deleteAirport(airport.id);
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
      body: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // List existing airports
              Expanded(
                child: airportsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(child: Text('No airports yet.'));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final airport = list[i];
                        return ListTile(
                          title: Text(airport.name),
                          subtitle: Text(airport.code),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _startEdit(airport),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _delete(airport),
                              ),
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

              // Add/Edit form
              Form(
                key: _formKey,
                child: FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Airport Name'),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter a name' : null,
                      ),
                      TextFormField(
                        controller: _codeCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Airport Code'),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter a code' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy ? null : _submit,
                              child: Text(
                                _editing == null
                                    ? 'Add Airport'
                                    : 'Update Airport',
                              ),
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
      ),
    );
  }
}

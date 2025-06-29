import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_seat_model.dart';
import '../providers/child_seat_notifier.dart';

class ChildSeatScreen extends ConsumerStatefulWidget {
  static const routeName = '/child_seats';
  const ChildSeatScreen({super.key});

  @override
  ConsumerState<ChildSeatScreen> createState() => _ChildSeatScreenState();
}

class _ChildSeatScreenState extends ConsumerState<ChildSeatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeCtrl = TextEditingController();
  final _ageCtrl  = TextEditingController();

  ChildSeat? _editing;

  @override
  void dispose() {
    _typeCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _startEdit(ChildSeat seat) {
    setState(() {
      _editing = seat;
      _typeCtrl.text = seat.type;
      _ageCtrl.text  = seat.age;
    });
  }

  void _cancelEdit() {
    _editing = null;
    _typeCtrl.clear();
    _ageCtrl.clear();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final type = _typeCtrl.text.trim();
    final age  = _ageCtrl.text.trim();
    final notifier = ref.read(childSeatNotifierProvider.notifier);

    try {
      if (_editing == null) {
        await notifier.addChildSeat(type, age);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Child seat added')));
      } else {
        await notifier.updateChildSeat(_editing!.id, type, age);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Child seat updated')));
        _cancelEdit();
      }
      _typeCtrl.clear();
      _ageCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(ChildSeat seat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Child Seat?'),
        content: Text('Really delete "${seat.type}, ${seat.age}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(childSeatNotifierProvider.notifier).deleteChildSeat(seat.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(childSeatsStreamProvider);
    final isBusy    = ref.watch(childSeatNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Child Seats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // existing seats
          Expanded(
            child: seatsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('No seats yet.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final seat = list[i];
                    return ListTile(
                      title: Text('${seat.type} — ${seat.age}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit),   onPressed: () => _startEdit(seat)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(seat)),
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
            child: Column(children: [
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Type'),
                validator: (v) => v == null || v.isEmpty ? 'Enter type' : null,
              ),
              TextFormField(
                controller: _ageCtrl,
                decoration: const InputDecoration(labelText: 'Age (e.g. 1–2 years)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter age/range' : null,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : _submit,
                    child: Text(_editing == null ? 'Add Seat' : 'Update'),
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
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

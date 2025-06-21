import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../providers/car_notifier.dart';

class CarScreen extends ConsumerStatefulWidget {
  const CarScreen({super.key});

  static const routeName = '/car';

  @override
  CarScreenState createState() => CarScreenState();
}

class CarScreenState extends ConsumerState<CarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();

  Car? _editing;

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Car car) {
    setState(() {
      _editing = car;
      _makeCtrl.text = car.make;
      _modelCtrl.text = car.model;
      _regCtrl.text = car.registration;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _makeCtrl.clear();
      _modelCtrl.clear();
      _regCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final reg = _regCtrl.text.trim();
    final notifier = ref.read(carNotifierProvider.notifier);

    try {
      if (_editing == null) {
        await notifier.addCar(make, model, reg);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Car added')));
      } else {
        await notifier.updateCar(_editing!.id, make, model, reg);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Car updated')));
        _cancelEdit();
      }
      _makeCtrl.clear();
      _modelCtrl.clear();
      _regCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(Car car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Car?'),
        content: Text('Really delete "${car.make} ${car.model}"?'),
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
        await ref.read(carNotifierProvider.notifier).deleteCar(car.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Car deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carsStreamProvider);
    final isBusy = ref.watch(carNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Cars')),
      body: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // List existing cars
              Expanded(
                child: carsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(child: Text('No cars added.'));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final car = list[i];
                        return ListTile(
                          title: Text('${car.make} ${car.model}'),
                          subtitle: Text('Reg: ${car.registration}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _startEdit(car),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _delete(car),
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

              // Add/Edit form with traversal
              Form(
                key: _formKey,
                child: FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _makeCtrl,
                        decoration: const InputDecoration(labelText: 'Make'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter make' : null,
                      ),
                      TextFormField(
                        controller: _modelCtrl,
                        decoration: const InputDecoration(labelText: 'Model'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter model' : null,
                      ),
                      TextFormField(
                        controller: _regCtrl,
                        decoration: const InputDecoration(labelText: 'Registration'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter registration' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy ? null : _submit,
                              child: Text(
                                _editing == null ? 'Add Car' : 'Update Car',
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

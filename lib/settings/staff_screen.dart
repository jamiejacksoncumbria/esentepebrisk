import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_model.dart';
import '../providers/staff_notifer.dart';

class StaffScreen extends ConsumerWidget {
  static const routeName = '/staff';  // ← add this

  const StaffScreen({super.key});

  void _showForm(BuildContext context, WidgetRef ref, [Staff? staff]) {
    final nameC = TextEditingController(text: staff?.name);
    final lastC = TextEditingController(text: staff?.lastName);
    final phoneC = TextEditingController(text: staff?.phone);
    final emailC = TextEditingController(text: staff?.email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(staff == null ? 'Add Staff' : 'Edit Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: InputDecoration(labelText: 'First Name')),
            TextField(controller: lastC, decoration: InputDecoration(labelText: 'Last Name')),
            TextField(controller: phoneC, decoration: InputDecoration(labelText: 'Phone')),
            TextField(controller: emailC, decoration: InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final repo = ref.read(staffRepoProvider);
              if (staff == null) {
                repo.addStaff(Staff(
                  id: '',
                  name: nameC.text,
                  lastName: lastC.text,
                  phone: phoneC.text,
                  email: emailC.text,
                ));
              } else {
                repo.updateStaff(Staff(
                  id: staff.id,
                  name: nameC.text,
                  lastName: lastC.text,
                  phone: phoneC.text,
                  email: emailC.text,
                ));
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Settings — Staff')),
      body: staffAsync.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final s = list[i];
            return ListTile(
              title: Text('${s.name} ${s.lastName}'),
              subtitle: Text('${s.email} • ${s.phone}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit), onPressed: () => _showForm(context, ref, s)),
                IconButton(icon: Icon(Icons.delete), onPressed: () => ref.read(staffRepoProvider).deleteStaff(s.id)),
              ]),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: Icon(Icons.add),
      ),
    );
  }
}

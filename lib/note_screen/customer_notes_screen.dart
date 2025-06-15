import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../models/staff_model.dart';

import '../providers/staff_notifer.dart';
import '../repositories/customer_repository.dart';

class CustomerNotesScreen extends ConsumerStatefulWidget {
  final String customerId;
  final VoidCallback? onNotesUpdated;

  const CustomerNotesScreen({
    super.key,
    required this.customerId,
    this.onNotesUpdated,
    required Future<void> Function() onUpdate,
  });

  @override
  ConsumerState<CustomerNotesScreen> createState() =>
      _CustomerNotesScreenState();
}

class _CustomerNotesScreenState extends ConsumerState<CustomerNotesScreen> {
  final CustomerRepository _repository = CustomerRepository();
  final TextEditingController _noteController = TextEditingController();
  List<NoteModel> _notes = [];
  Staff? _selectedStaff;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _loading = true;
    });
    try {
      final notes = await _repository.getNotes(widget.customerId);
      setState(() {
        _notes = notes;
      });
    } catch (_) {}
    setState(() {
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _selectedStaff == null) return;

    await _repository.addNoteWithStaff(
      widget.customerId,
      text,
      _selectedStaff!.id,
      '${_selectedStaff!.name} ${_selectedStaff!.lastName}',
    );
    _noteController.clear();
    await _fetchNotes();
    widget.onNotesUpdated?.call();
  }

  Future<void> _editNote(NoteModel note) async {
    final controller = TextEditingController(text: note.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Enter note text'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, controller.text.trim().isEmpty ? null : controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != note.text) {
      final updatedNote = note.copyWith(text: result);
      await _repository.updateNote(widget.customerId, updatedNote);
      await _fetchNotes();
      widget.onNotesUpdated?.call();
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteNote(widget.customerId, note.id);
      await _fetchNotes();
      widget.onNotesUpdated?.call();
    }
  }

  String formatDateWithOrdinal(DateTime date) {
    final day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    final formattedDay = DateFormat('EEEE d').format(date);
    final formattedRest = DateFormat('MMMM y').format(date);
    return '$formattedDay$suffix $formattedRest';
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                staffAsync.when(
                  data: (staffList) => DropdownButtonFormField<Staff>(
                    value: _selectedStaff,
                    hint: const Text('Select Staff Member'),
                    isExpanded: true,
                    items: staffList.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text('${s.name} ${s.lastName}'),
                      );
                    }).toList(),
                    onChanged: (s) => setState(() => _selectedStaff = s),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Staff',
                    ),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error loading staff: $e'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Add Note',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _addNote, child: const Text('Add')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                ? const Center(child: Text('No notes yet'))
                : ListView.separated(
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return ListTile(
                  title: Text(note.text),
                  subtitle: Text(
                    '${formatDateWithOrdinal(note.createdAt.toDate().toLocal())} — ${note.staffName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editNote(note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNote(note),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

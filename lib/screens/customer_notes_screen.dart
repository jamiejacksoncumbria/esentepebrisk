import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../repositories/customer_repository.dart';

class CustomerNotesScreen extends StatefulWidget {
  final String customerId;
  final VoidCallback? onNotesUpdated;

  const CustomerNotesScreen({
    Key? key,
    required this.customerId,
    this.onNotesUpdated, required Future<void> Function() onUpdate,
  }) : super(key: key);

  @override
  State<CustomerNotesScreen> createState() => _CustomerNotesScreenState();
}

class _CustomerNotesScreenState extends State<CustomerNotesScreen> {
  final CustomerRepository _repository = CustomerRepository();

  final TextEditingController _noteController = TextEditingController();
  List<NoteModel> _notes = [];
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
    } catch (e) {
      // handle error if needed
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    await _repository.addNote(widget.customerId, text);
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
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              Navigator.pop(context, newText.isEmpty ? null : newText);
            },
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Notes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
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
                ElevatedButton(
                  onPressed: _addNote,
                  child: const Text('Add'),
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
                    note.createdAt.toDate().toLocal().toString(),
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

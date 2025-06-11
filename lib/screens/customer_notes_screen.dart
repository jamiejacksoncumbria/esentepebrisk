import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../repositories/customer_repository.dart';

class CustomerNotesScreen extends StatefulWidget {
  final String customerId;
  final CustomerRepository repository;

  const CustomerNotesScreen({
    Key? key,
    required this.customerId,
    required this.repository,
  }) : super(key: key);

  @override
  State<CustomerNotesScreen> createState() => _CustomerNotesScreenState();
}

class _CustomerNotesScreenState extends State<CustomerNotesScreen> {
  List<NoteModel> _notes = [];
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await widget.repository.getNotes(widget.customerId);
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _addNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;

    await widget.repository.addNote(widget.customerId, content);
    _noteController.clear();
    _loadNotes();
  }

  Future<void> _deleteNote(String noteId) async {
    await widget.repository.deleteNote(widget.customerId, noteId);
    _loadNotes();
  }

  Future<void> _editNoteDialog(NoteModel note) async {
    final controller = TextEditingController(text: note.content);

    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Update your note...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty && updated != note.content) {
      await widget.repository.updateNote(
        widget.customerId,
        note.copyWith(content: updated),
      );
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Notes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Enter a note',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addNote,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return ListTile(
                  title: Text(note.content),
                  subtitle: Text(note.createdAt.toDate().toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editNoteDialog(note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNote(note.id),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer_model.dart';
import '../models/note_model.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Search and include latest note snippet per customer
  Future<List<CustomerModel>> searchCustomers(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('searchTerms', arrayContains: query.toLowerCase())
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();

      final list = <CustomerModel>[];

      for (final doc in snapshot.docs) {
        final customer = CustomerModel.fromMap(doc.data());
        final notes = await getNotes(customer.id);
        final snippet = notes.isNotEmpty ? notes.first.text : null;

        list.add(customer.copyWith(latestNoteSnippet: snippet));
      }

      return list;
    } catch (e) {
      debugPrint('Search error: $e');
      rethrow;
    }
  }

  Future<String> createCustomer(CustomerModel customer) async {
    final doc = _firestore.collection('customers').doc();
    final withId = customer.copyWith(id: doc.id);
    await doc.set(withId.toMap());
    return doc.id;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .update(customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _deletePhotos(id);
    await _firestore.collection('customers').doc(id).delete();
  }

  Future<void> _deletePhotos(String customerId) async {
    try {
      final ref = _storage.ref().child('customers/$customerId');
      final all = await ref.listAll();
      await Future.wait(all.items.map((i) => i.delete()));
    } catch (_) {
      debugPrint('Photo delete failed');
    }
  }

  Future<String?> uploadPhoto({
    required String customerId,
    required XFile file,
    required String type,
  }) async {
    final ref = _storage
        .ref()
        .child('customers/$customerId/$type-${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = ref.putData(await file.readAsBytes());
    final snap = await task;
    return (snap.state == TaskState.success) ? await ref.getDownloadURL() : null;
  }

  // Notes CRUD
  Future<List<NoteModel>> getNotes(String customerId) async {
    final snap = await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => NoteModel.fromMap(d.data(), d.id)).toList();
  }

  Future<void> addNote(String customerId, String text) async {
    final ref = _firestore
        .collection('customers')
        .doc(customerId)
        .collection('notes')
        .doc();
    await ref.set({
      'id': ref.id,
      'text': text,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateNote(String customerId, NoteModel note) async {
    await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap());
  }

  Future<void> deleteNote(String customerId, String noteId) async {
    await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}

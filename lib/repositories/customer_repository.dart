import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer_model.dart';


class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore.collection('customers')
          .where('searchTerms', arrayContains: query.toLowerCase())
          .limit(15)
          .get();

      return snapshot.docs.map((doc) => CustomerModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      rethrow;
    }
  }

  Future<String> createCustomer(CustomerModel customer) async {
    try {
      final docRef = _firestore.collection('customers').doc();
      final customerWithId = customer.copyWith(id: docRef.id);
      await docRef.set(customerWithId.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Create error: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _firestore.collection('customers').doc(customer.id)
          .update(customer.toMap());
    } catch (e) {
      debugPrint('Update error: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      // First delete photos from storage
      await _deleteCustomerPhotos(id);
      // Then delete the document
      await _firestore.collection('customers').doc(id).delete();
    } catch (e) {
      debugPrint('Delete error: $e');
      rethrow;
    }
  }

  Future<void> _deleteCustomerPhotos(String customerId) async {
    try {
      final ref = _storage.ref().child('customers/$customerId');
      final listResult = await ref.listAll();
      await Future.wait(listResult.items.map((item) => item.delete()));
    } catch (e) {
      debugPrint('Photo delete error: $e');
      // Continue even if photo deletion fails
    }
  }

  Future<String?> uploadPhoto({
    required String customerId,
    required XFile file,
    required String type,
  }) async {
    try {
      final ref = _storage.ref()
          .child('customers/$customerId/$type-${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putData(await file.readAsBytes());
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}
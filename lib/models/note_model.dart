import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String text;
  final Timestamp createdAt;

  NoteModel({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: map['id'] as String,
      text: map['text'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  NoteModel copyWith({
    String? id,
    String? text,
    Timestamp? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

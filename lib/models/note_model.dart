import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String content;
  final Timestamp createdAt;

  NoteModel({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt,
    };
  }
  NoteModel copyWith({String? content}) {
    return NoteModel(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }

}

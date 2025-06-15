import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String text;
  final Timestamp createdAt;
  final String staffId;
  final String staffName;

  NoteModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.staffId,
    required this.staffName,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': createdAt,
      'staffId': staffId,
      'staffName': staffName,
    };
  }

  NoteModel copyWith({
    String? id,
    String? text,
    Timestamp? createdAt,
    String? staffId,
    String? staffName,
  }) {
    return NoteModel(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
    );
  }
}

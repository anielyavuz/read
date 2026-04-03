import 'package:cloud_firestore/cloud_firestore.dart';

/// A user note for a specific book — can contain text and/or a page photo.
/// Firestore path: userBooks/{userId}/library/{bookId}/notes/{noteId}
class BookNote {
  final String? id;
  final String? content;
  final int? pageNumber;
  final String? imageBase64;
  final DateTime? createdAt;

  const BookNote({
    this.id,
    this.content,
    this.pageNumber,
    this.imageBase64,
    this.createdAt,
  });

  factory BookNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookNote(
      id: doc.id,
      content: data['content'] as String?,
      pageNumber: data['pageNumber'] as int?,
      imageBase64: data['imageBase64'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'pageNumber': pageNumber,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;
  bool get hasContent => content != null && content!.isNotEmpty;
}

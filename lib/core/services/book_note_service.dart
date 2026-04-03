import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_note.dart';

/// Firestore service for book notes (text + page photos).
/// Path: userBooks/{userId}/library/{bookId}/notes/{noteId}
class BookNoteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BookNoteService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _notesRef(String bookId) {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    return _firestore
        .collection('userBooks')
        .doc(uid)
        .collection('library')
        .doc(bookId)
        .collection('notes');
  }

  /// Add a new note for a book.
  Future<String> addNote(String bookId, BookNote note) async {
    if (_uid == null) throw Exception('Not authenticated');
    final doc = await _notesRef(bookId).add(note.toFirestore());
    return doc.id;
  }

  /// Update an existing note.
  Future<void> updateNote(String bookId, String noteId, BookNote note) async {
    if (_uid == null) return;
    await _notesRef(bookId).doc(noteId).update(note.toFirestore());
  }

  /// Delete a note.
  Future<void> deleteNote(String bookId, String noteId) async {
    if (_uid == null) return;
    await _notesRef(bookId).doc(noteId).delete();
  }

  /// Load all notes for a book, ordered by creation date (newest first).
  Future<List<BookNote>> getNotes(String bookId) async {
    if (_uid == null) return [];
    final snapshot = await _notesRef(bookId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => BookNote.fromFirestore(doc)).toList();
  }

  /// Get count of notes for a book.
  Future<int> getNoteCount(String bookId) async {
    if (_uid == null) return 0;
    final snapshot = await _notesRef(bookId).count().get();
    return snapshot.count ?? 0;
  }
}

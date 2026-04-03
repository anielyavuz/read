import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/scanned_page.dart';

/// Firestore service for persisting scanned book pages.
/// Path: userBooks/{userId}/library/{bookId}/scannedPages/{pageId}
class ScannedPagesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ScannedPagesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _pagesRef(String bookId) {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    return _firestore
        .collection('userBooks')
        .doc(uid)
        .collection('library')
        .doc(bookId)
        .collection('scannedPages');
  }

  /// Save multiple scanned pages for a book (batch write).
  Future<void> savePages(String bookId, List<ScannedPage> pages) async {
    if (_uid == null || pages.isEmpty) return;
    final ref = _pagesRef(bookId);
    final batch = _firestore.batch();

    for (final page in pages) {
      final doc = ref.doc(); // auto-generated ID
      batch.set(doc, page.toFirestore());
    }

    await batch.commit();
  }

  /// Load all scanned pages for a book, ordered by page number.
  Future<List<ScannedPage>> loadPages(String bookId) async {
    if (_uid == null) return [];
    final snapshot = await _pagesRef(bookId)
        .orderBy('pageNumber', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ScannedPage.fromFirestore(doc))
        .where((p) => p.extractedText.isNotEmpty)
        .toList();
  }

  /// Delete a single scanned page.
  Future<void> deletePage(String bookId, String pageId) async {
    if (_uid == null) return;
    await _pagesRef(bookId).doc(pageId).delete();
  }

  /// Delete all scanned pages for a book.
  Future<void> deleteAllPages(String bookId) async {
    if (_uid == null) return;
    final snapshot = await _pagesRef(bookId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

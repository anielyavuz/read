import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../models/user_book.dart';

class BookLibraryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BookLibraryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _booksRef =>
      _firestore.collection('books');

  CollectionReference<Map<String, dynamic>> _userBooksRef(String uid) =>
      _firestore.collection('userBooks').doc(uid).collection('library');

  Future<void> addBookToLibrary({
    required Book book,
    required String status,
  }) async {
    if (_uid == null) return;

    // Cache book globally
    await _booksRef.doc(book.id).set(book.toFirestore(), SetOptions(merge: true));

    // Add to user library
    final isFinished = status == 'finished';
    final userBook = UserBook(
      bookId: book.id,
      status: status,
      currentPage: isFinished ? book.pageCount : 0,
      totalPages: book.pageCount,
      startDate: status == 'reading' ? DateTime.now() : null,
      finishDate: isFinished ? DateTime.now() : null,
      title: book.title,
      authors: book.authors,
      coverUrl: book.coverUrl,
    );

    final data = userBook.toFirestore();

    // If adding as TBR, assign next sortOrder
    if (status == 'tbr') {
      final nextOrder = await _getNextTbrSortOrder();
      data['sortOrder'] = nextOrder;
    }

    await _userBooksRef(_uid!).doc(book.id).set(data);
  }

  Future<int> _getNextTbrSortOrder() async {
    if (_uid == null) return 1;
    final snapshot = await _userBooksRef(_uid!)
        .where('status', isEqualTo: 'tbr')
        .get();
    if (snapshot.docs.isEmpty) return 1;
    int maxOrder = 0;
    for (final doc in snapshot.docs) {
      final order = doc.data()['sortOrder'] as int? ?? 0;
      if (order > maxOrder) maxOrder = order;
    }
    return maxOrder + 1;
  }

  Future<List<UserBook>> getUserBooks({String? status}) async {
    if (_uid == null) return [];

    Query<Map<String, dynamic>> query = _userBooksRef(_uid!);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    final books = snapshot.docs.map((doc) => UserBook.fromFirestore(doc)).toList();

    // Fallback sort for TBR books without sortOrder
    if (status == 'tbr') {
      books.sort((a, b) => (a.sortOrder ?? 999999).compareTo(b.sortOrder ?? 999999));
    }

    return books;
  }

  Future<UserBook?> getUserBook(String bookId) async {
    if (_uid == null) return null;
    final doc = await _userBooksRef(_uid!).doc(bookId).get();
    if (!doc.exists) return null;
    return UserBook.fromFirestore(doc);
  }

  Future<void> updateProgress({
    required String bookId,
    required int currentPage,
  }) async {
    if (_uid == null) return;
    await _userBooksRef(_uid!).doc(bookId).update({
      'currentPage': currentPage,
      'lastReadDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> markAsFinished(String bookId) async {
    if (_uid == null) return;
    final doc = await _userBooksRef(_uid!).doc(bookId).get();
    if (!doc.exists) return;

    final totalPages = doc.data()?['totalPages'] ?? 0;
    await _userBooksRef(_uid!).doc(bookId).update({
      'status': 'finished',
      'currentPage': totalPages,
      'finishDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> markAsReading(String bookId) async {
    if (_uid == null) return;
    await _userBooksRef(_uid!).doc(bookId).update({
      'status': 'reading',
      'startDate': Timestamp.fromDate(DateTime.now()),
      'finishDate': FieldValue.delete(),
      'sortOrder': FieldValue.delete(),
    });
  }

  Future<void> updateTotalPages({
    required String bookId,
    required int totalPages,
  }) async {
    if (_uid == null) return;
    final doc = await _userBooksRef(_uid!).doc(bookId).get();
    if (!doc.exists) return;
    final currentPage = doc.data()?['currentPage'] ?? 0;
    final updates = <String, dynamic>{'totalPages': totalPages};
    if (currentPage > totalPages) {
      updates['currentPage'] = totalPages;
    }
    await _userBooksRef(_uid!).doc(bookId).update(updates);
  }

  Future<void> updateCustomCover({
    required String bookId,
    required String? base64Image,
  }) async {
    if (_uid == null) return;
    if (base64Image != null) {
      await _userBooksRef(_uid!).doc(bookId).update({
        'customCoverBase64': base64Image,
      });
    } else {
      await _userBooksRef(_uid!).doc(bookId).update({
        'customCoverBase64': FieldValue.delete(),
      });
    }
  }

  Future<void> removeBook(String bookId) async {
    if (_uid == null) return;
    await _userBooksRef(_uid!).doc(bookId).delete();
  }

  // --- Tag Management ---

  /// Update tags for a specific book in user's library.
  Future<void> updateBookTags({
    required String bookId,
    required List<String> tags,
  }) async {
    if (_uid == null) return;
    await _userBooksRef(_uid!).doc(bookId).update({'tags': tags});
  }

  /// Get all unique tags the user has used across their library.
  Future<List<String>> getUserTags() async {
    if (_uid == null) return [];
    final snapshot = await _userBooksRef(_uid!).get();
    final tagSet = <String>{};
    for (final doc in snapshot.docs) {
      final tags = List<String>.from(doc.data()['tags'] ?? []);
      tagSet.addAll(tags);
    }
    final sorted = tagSet.toList()..sort();
    return sorted;
  }

  Future<void> reorderTbrBooks(List<UserBook> reorderedBooks) async {
    if (_uid == null) return;
    final batch = _firestore.batch();
    for (int i = 0; i < reorderedBooks.length; i++) {
      final docRef = _userBooksRef(_uid!).doc(reorderedBooks[i].bookId);
      batch.update(docRef, {'sortOrder': i + 1});
    }
    await batch.commit();
  }
}

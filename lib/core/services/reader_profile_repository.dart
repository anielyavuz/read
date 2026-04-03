import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reader_profile.dart';

class ReaderProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReaderProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _profileDocRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('readerProfile')
          .doc('current');

  Future<void> setReaderProfile(ReaderProfile profile) async {
    if (_uid == null) return;
    await _profileDocRef(_uid!).set(profile.toFirestore());
  }

  Future<ReaderProfile?> getReaderProfile() async {
    if (_uid == null) return null;

    try {
      final doc = await _profileDocRef(_uid!).get();
      if (!doc.exists) return null;
      return ReaderProfile.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Stream<ReaderProfile?> streamReaderProfile() {
    if (_uid == null) return Stream.value(null);

    return _profileDocRef(_uid!).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ReaderProfile.fromFirestore(doc);
    });
  }
}

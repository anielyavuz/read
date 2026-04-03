import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationPreferencesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// Read notification preferences from user document
  Future<NotificationPreferences> getPreferences() async {
    try {
      if (_uid == null) return const NotificationPreferences();
      final doc = await _userDoc.get();
      if (!doc.exists) return const NotificationPreferences();
      final data = doc.data();
      final prefsData = data?['notificationPrefs'] as Map<String, dynamic>?;
      return NotificationPreferences.fromFirestore(prefsData);
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  /// Write notification preferences to Firestore
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    try {
      if (_uid == null) return;
      await _userDoc.update({
        'notificationPrefs': prefs.toFirestore(),
      });
    } catch (_) {
      // Non-critical: preference save failure
    }
  }

  /// Convenience method to save reading times
  Future<void> saveReadingTime(
    String weekdayTime,
    String weekendTime,
  ) async {
    try {
      final current = await getPreferences();
      final updated = current.copyWith(
        weekdayTime: weekdayTime,
        weekendTime: weekendTime,
      );
      await updatePreferences(updated);
    } catch (_) {
      // Non-critical
    }
  }
}

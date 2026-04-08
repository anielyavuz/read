import 'package:cloud_firestore/cloud_firestore.dart';

class SystemInfoService {
  final FirebaseFirestore _firestore;
  String? _cachedGeminiKey;
  String? _cachedGeminiModel;
  String? _cachedGroqKey;
  String? _cachedGroqImageKey;
  bool _fetched = false;

  SystemInfoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> getGeminiApiKey() async {
    await _ensureFetched();
    return _cachedGeminiKey!;
  }

  Future<String> getGeminiModelName() async {
    await _ensureFetched();
    return _cachedGeminiModel!;
  }

  Future<String> getGroqApiKey() async {
    await _ensureFetched();
    return _cachedGroqKey!;
  }

  Future<String> getGroqImageKey() async {
    await _ensureFetched();
    return _cachedGroqImageKey!;
  }

  Future<void> _ensureFetched() async {
    if (_fetched) return;
    try {
      final doc =
          await _firestore.collection('system').doc('systemInfos').get();
      final data = doc.data();
      final gemini = data?['gemini'] as Map<String, dynamic>?;
      _cachedGeminiKey = gemini?['key'] as String? ?? '';
      _cachedGeminiModel =
          gemini?['modelName'] as String? ?? 'gemini-2.5-flash';
      _cachedGroqKey = data?['groqKey'] as String? ?? '';
      _cachedGroqImageKey = data?['groqImageKey'] as String? ?? '';
    } catch (_) {
      _cachedGeminiKey = '';
      _cachedGeminiModel = 'gemini-2.5-flash';
      _cachedGroqKey = '';
      _cachedGroqImageKey = '';
    }
    _fetched = true;
  }
}

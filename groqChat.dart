/// Bağımsız Groq Chat Servisi
/// Başka projelere taşınabilir. Bağımlılık: http paketi + cloud_firestore
///
/// Kullanım:
///   final groq = GroqChatService(firestore: FirebaseFirestore.instance);
///   final response = await groq.ask('Merhaba');
///   print(response.reply);
///
///   // Veya JSON yanıt isteyen chat:
///   final chatResponse = await groq.chat(
///     userMessage: 'Makarna tarifi ver',
///     systemPrompt: 'Sen bir asistansın...',
///   );
///   print(chatResponse); // Map<String, dynamic>

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// ─── Firebase Path (DOLDUR) ──────────────────────────────────────────────
/// Firestore'da API key'in tutulduğu doküman yolu
const _firestoreDocPath = ''; // örn: 'system/general'
/// Dokümandaki API key alan adı
const _apiKeyField = 'groqApiKey';

/// Dokümandaki model alan adı (opsiyonel, boş bırakılabilir)
const _modelField = 'groqModelName';
// ─────────────────────────────────────────────────────────────────────────

class GroqChatService {
  final FirebaseFirestore _firestore;

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _defaultModel = 'llama-3.3-70b-versatile';
  static const double _temperature = 0.3;
  static const int _maxTokens = 1024;
  static const int _maxHistoryMessages = 20;

  String? _apiKey;
  String _model = _defaultModel;

  /// Konuşma geçmişi
  final List<Map<String, String>> _history = [];

  GroqChatService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Lazy init — Firestore'dan API key ve model adını çeker
  Future<void> _ensureInitialized() async {
    if (_apiKey != null) return;

    assert(
      _firestoreDocPath.isNotEmpty,
      'groqChat.dart: _firestoreDocPath boş! Firestore yolunu doldur.',
    );

    final doc = await _firestore.doc(_firestoreDocPath).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('Groq config dokümanı bulunamadı: $_firestoreDocPath');
    }

    _apiKey = data[_apiKeyField] as String?;
    final modelName = data[_modelField] as String? ?? '';
    if (modelName.isNotEmpty) _model = modelName;

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
        'Groq API key Firestore\'da tanımlı değil ($_apiKeyField)',
      );
    }
  }

  // ─── Basit Soru-Cevap ───────────────────────────────────────────────

  /// Tek soru gönderir, yanıt + kullanım bilgisi döner.
  /// Konuşma geçmişi tutulur.
  Future<GroqResponse> ask(
    String prompt, {
    String system = 'Sen yardımcı bir asistansın.',
    int maxTokens = _maxTokens,
  }) async {
    await _ensureInitialized();

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
    ];

    _history.add({'role': 'user', 'content': prompt});

    final recentHistory = _history.length > _maxHistoryMessages
        ? _history.sublist(_history.length - _maxHistoryMessages)
        : _history;
    messages.addAll(recentHistory);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': _temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw GroqApiException(
        'Groq API hatası: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq boş yanıt döndü');
    }

    final reply = choices[0]['message']['content'] as String? ?? '';
    _history.add({'role': 'assistant', 'content': reply});

    final usage = data['usage'] as Map<String, dynamic>? ?? {};
    final headers = response.headers;

    final groqUsage = GroqUsage(
      promptTokens: usage['prompt_tokens'] as int? ?? 0,
      completionTokens: usage['completion_tokens'] as int? ?? 0,
      totalTokens: usage['total_tokens'] as int? ?? 0,
      remainingRequests: _parseInt(headers['x-ratelimit-remaining-requests']),
      limitRequests: _parseInt(headers['x-ratelimit-limit-requests']),
      remainingTokens: _parseInt(headers['x-ratelimit-remaining-tokens']),
      limitTokens: _parseInt(headers['x-ratelimit-limit-tokens']),
      resetRequests: headers['x-ratelimit-reset-requests'],
      resetTokens: headers['x-ratelimit-reset-tokens'],
    );

    debugPrint('╔══ GROQ ══════════════════════');
    debugPrint('║ Model: $_model');
    debugPrint(
      '║ Tokens: ${groqUsage.totalTokens} '
      '(prompt: ${groqUsage.promptTokens}, completion: ${groqUsage.completionTokens})',
    );
    debugPrint(
      '║ Rate: ${groqUsage.remainingRequests}/${groqUsage.limitRequests} req',
    );
    debugPrint('╚══════════════════════════════');

    return GroqResponse(reply: reply, usage: groqUsage);
  }

  // ─── JSON Chat ──────────────────────────────────────────────────────

  /// JSON formatında yanıt dönen chat.
  /// [systemPrompt] ile davranışı belirle, [userMessage] ile soru sor.
  /// Yanıt otomatik parse edilir, hata olursa ham string döner.
  Future<Map<String, dynamic>> chat({
    required String userMessage,
    required String systemPrompt,
    int maxTokens = 2048,
  }) async {
    await _ensureInitialized();

    _history.add({'role': 'user', 'content': userMessage});

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];
    final recentHistory = _history.length > _maxHistoryMessages
        ? _history.sublist(_history.length - _maxHistoryMessages)
        : _history;
    messages.addAll(recentHistory);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': _temperature,
        'max_tokens': maxTokens,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      _history.removeLast();
      throw GroqApiException(
        'Groq API hatası: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      _history.removeLast();
      throw Exception('Groq boş yanıt döndü');
    }

    final reply = choices[0]['message']['content'] as String? ?? '';
    _history.add({'role': 'assistant', 'content': reply});

    final usage = data['usage'] as Map<String, dynamic>? ?? {};
    final headers = response.headers;
    debugPrint('╔══ GROQ CHAT ═════════════════');
    debugPrint(
      '║ Tokens: ${usage['total_tokens']} '
      '(prompt: ${usage['prompt_tokens']}, completion: ${usage['completion_tokens']})',
    );
    debugPrint(
      '║ Rate: ${headers['x-ratelimit-remaining-requests']}/${headers['x-ratelimit-limit-requests']} req',
    );
    debugPrint('╚══════════════════════════════');

    return _safeJsonDecode(reply);
  }

  // ─── Yardımcılar ───────────────────────────────────────────────────

  /// Geçmişi temizler (yeni konuşma başlatmak için)
  void clearHistory() => _history.clear();

  /// Geçmiş mesaj sayısı
  int get historyLength => _history.length;

  static int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// JSON parse — bozuk yanıtları temizlemeye çalışır
  static Map<String, dynamic> _safeJsonDecode(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } on FormatException {
      cleaned = cleaned.replaceAll(
        RegExp(r'[\x00-\x1F\x7F]', multiLine: true),
        ' ',
      );
      cleaned = cleaned.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
      return jsonDecode(cleaned) as Map<String, dynamic>;
    }
  }
}

// ─── Modeller ─────────────────────────────────────────────────────────

class GroqResponse {
  final String reply;
  final GroqUsage usage;
  const GroqResponse({required this.reply, required this.usage});
}

class GroqUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int? remainingRequests;
  final int? limitRequests;
  final int? remainingTokens;
  final int? limitTokens;
  final String? resetRequests;
  final String? resetTokens;

  const GroqUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.remainingRequests,
    this.limitRequests,
    this.remainingTokens,
    this.limitTokens,
    this.resetRequests,
    this.resetTokens,
  });

  bool get isNearRateLimit =>
      remainingRequests != null && remainingRequests! < 5;
}

class GroqApiException implements Exception {
  final String message;
  final int statusCode;
  const GroqApiException(this.message, {required this.statusCode});

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() => 'GroqApiException($statusCode): $message';
}

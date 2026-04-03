import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'system_info_service.dart';

/// Unified AI chat service: Groq (primary) with Gemini (fallback).
///
/// Groq is used first for faster, free-tier responses.
/// If Groq returns 429 (rate limit) or fails, falls back to Gemini.
///
/// Only for text-in / JSON-out calls. Vision/multimodal stays on Gemini directly.
class AiChatService {
  final SystemInfoService _systemInfoService;

  static const String _groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'llama-3.3-70b-versatile';
  static const double _temperature = 0.3;

  AiChatService({required SystemInfoService systemInfoService})
      : _systemInfoService = systemInfoService;

  /// Sends a prompt and returns parsed JSON response.
  /// Tries Groq first; on rate limit or failure, falls back to Gemini.
  Future<Map<String, dynamic>> generateJson({
    required String prompt,
    int maxTokens = 2048,
  }) async {
    // Try Groq first
    try {
      final groqKey = await _systemInfoService.getGroqApiKey();
      if (groqKey.isNotEmpty) {
        final result = await _groqGenerate(
          apiKey: groqKey,
          prompt: prompt,
          maxTokens: maxTokens,
        );
        debugPrint('╔══ AI ═══ Groq OK ══════════════');
        return result;
      }
    } on GroqRateLimitException {
      debugPrint('╔══ AI ═══ Groq rate limited, falling back to Gemini');
    } catch (e) {
      debugPrint('╔══ AI ═══ Groq failed ($e), falling back to Gemini');
    }

    // Fallback to Gemini
    return _geminiGenerate(prompt: prompt);
  }

  // ─── Groq ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _groqGenerate({
    required String apiKey,
    required String prompt,
    required int maxTokens,
  }) async {
    final response = await http
        .post(
          Uri.parse(_groqBaseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _groqModel,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': _temperature,
            'max_tokens': maxTokens,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      throw GroqRateLimitException();
    }
    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq returned empty response');
    }

    final reply = choices[0]['message']['content'] as String? ?? '';

    // Log usage
    final usage = data['usage'] as Map<String, dynamic>? ?? {};
    final headers = response.headers;
    debugPrint('║ Model: $_groqModel');
    debugPrint('║ Tokens: ${usage['total_tokens']} '
        '(prompt: ${usage['prompt_tokens']}, completion: ${usage['completion_tokens']})');
    debugPrint('║ Rate: ${headers['x-ratelimit-remaining-requests']}/'
        '${headers['x-ratelimit-limit-requests']} req');
    debugPrint('╚══════════════════════════════════');

    return _safeJsonDecode(reply);
  }

  // ─── Gemini ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _geminiGenerate({
    required String prompt,
  }) async {
    final apiKey = await _systemInfoService.getGeminiApiKey();
    final modelName = await _systemInfoService.getGeminiModelName();

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 30));

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    debugPrint('╔══ AI ═══ Gemini fallback OK ═══');
    debugPrint('║ Model: $modelName');
    debugPrint('╚══════════════════════════════════');

    return _safeJsonDecode(text);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _safeJsonDecode(String raw) {
    var cleaned = raw.trim();
    // Remove markdown code fences
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } on FormatException {
      // Try harder: remove control chars and trailing commas
      cleaned = cleaned.replaceAll(
          RegExp(r'[\x00-\x1F\x7F]', multiLine: true), ' ');
      cleaned = cleaned.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
      return jsonDecode(cleaned) as Map<String, dynamic>;
    }
  }
}

class GroqRateLimitException implements Exception {
  @override
  String toString() => 'GroqRateLimitException: 429 Too Many Requests';
}

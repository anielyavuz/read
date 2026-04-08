import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;

/// Groq Vision API service for book cover scanning.
/// Uses Llama 4 Scout multimodal model as a fallback when Gemini fails.
class GroqVisionService {
  static const _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _maxTokens = 512;

  /// Analyzes a book cover image and returns parsed JSON result.
  /// Returns null on failure.
  static Future<Map<String, dynamic>?> scanBookCover({
    required String apiKey,
    required String imagePath,
  }) async {
    if (apiKey.isEmpty) return null;

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const prompt = '''
Look at this image. If this is a book cover or a photo of a book:
1. Extract the book title
2. Extract the author name (if visible)
3. Estimate or extract the page count (if visible, otherwise null)

Return ONLY a JSON object: {"title": "...", "author": "...", "pageCount": null or number, "isBook": true}

If this is NOT a book image, return: {"isBook": false}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': _maxTokens,
          'temperature': 0.2,
        }),
      );

      if (response.statusCode != 200) {
        dev.log(
          'Groq Vision API error: ${response.statusCode} — ${response.body}',
          name: 'GroqVisionService',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;

      final text =
          choices[0]['message']['content'] as String? ?? '';
      if (text.isEmpty) return null;

      // Parse JSON from response (might be wrapped in markdown code block)
      String jsonStr = text.trim();
      if (jsonStr.contains('```')) {
        final match =
            RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(1)!.trim();
        }
      }

      final usage = data['usage'] as Map<String, dynamic>? ?? {};
      dev.log(
        'Groq Vision OK — tokens: ${usage['total_tokens']} '
        '(prompt: ${usage['prompt_tokens']}, '
        'completion: ${usage['completion_tokens']})',
        name: 'GroqVisionService',
      );

      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      dev.log('Groq Vision failed: $e', name: 'GroqVisionService');
      return null;
    }
  }
}

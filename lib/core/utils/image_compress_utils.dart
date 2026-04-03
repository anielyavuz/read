import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses an image file to under [maxSizeBytes] and returns base64 string.
/// Progressively reduces quality until the target size is reached.
class ImageCompressUtils {
  static const int _maxSizeBytes = 200 * 1024; // 200 KB

  /// Compresses image at [filePath] to ≤200KB and returns base64 encoded string.
  static Future<String?> compressToBase64(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    // Start with reasonable dimensions and quality
    int quality = 80;
    int minWidth = 800;
    int minHeight = 800;

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      '${filePath}_compressed.jpg',
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;

    // Progressively reduce quality if still over 200KB
    var bytes = await result.readAsBytes();
    while (bytes.length > _maxSizeBytes && quality > 10) {
      quality -= 15;
      if (quality < 10) quality = 10;

      // Also reduce dimensions if quality alone isn't enough
      if (quality <= 40) {
        minWidth = 600;
        minHeight = 600;
      }
      if (quality <= 20) {
        minWidth = 400;
        minHeight = 400;
      }

      result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        '${filePath}_compressed.jpg',
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      bytes = await result.readAsBytes();
    }

    // Clean up temp file
    final tempFile = File('${filePath}_compressed.jpg');
    if (tempFile.existsSync()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    return base64Encode(bytes);
  }
}

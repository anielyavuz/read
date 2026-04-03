import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/scanned_page.dart';

/// Service for OCR text recognition on book page images.
class PageScannerService {
  /// Processes a list of image paths through OCR and returns scanned pages
  /// sorted by detected page number.
  Future<List<ScannedPage>> processImages(List<String> imagePaths) async {
    final recognizer = TextRecognizer();
    final pages = <ScannedPage>[];

    try {
      for (final path in imagePaths) {
        final inputImage = InputImage.fromFile(File(path));
        final recognized = await recognizer.processImage(inputImage);
        final text = recognized.text.trim();

        if (text.isEmpty) {
          pages.add(ScannedPage(
            extractedText: '',
            imagePath: path,
          ));
          continue;
        }

        final pageNumber = _extractPageNumber(text);
        pages.add(ScannedPage(
          pageNumber: pageNumber,
          extractedText: text,
          imagePath: path,
        ));
      }
    } finally {
      await recognizer.close();
    }

    // Sort: pages with detected numbers first (ascending), then unknown pages
    pages.sort((a, b) {
      if (a.pageNumber != null && b.pageNumber != null) {
        return a.pageNumber!.compareTo(b.pageNumber!);
      }
      if (a.pageNumber != null) return -1;
      if (b.pageNumber != null) return 1;
      return 0;
    });

    return pages;
  }

  /// Attempts to extract a page number from OCR text.
  ///
  /// Strategies:
  /// 1. Standalone number at the first or last line
  /// 2. Decorated number pattern (e.g., "- 42 -", "~ 42 ~")
  /// 3. Number at the start/end of first/last lines
  int? _extractPageNumber(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return null;

    final firstLine = lines.first.trim();
    final lastLine = lines.last.trim();

    // Strategy 1: Standalone number (1-4 digits)
    final standaloneRegex = RegExp(r'^\d{1,4}$');
    if (standaloneRegex.hasMatch(lastLine)) {
      return int.tryParse(lastLine);
    }
    if (standaloneRegex.hasMatch(firstLine)) {
      return int.tryParse(firstLine);
    }

    // Strategy 2: Decorated number (e.g., "- 42 -", "~ 42 ~", "— 42 —")
    final decoratedRegex = RegExp(r'^[\s\-–—~\*]*(\d{1,4})[\s\-–—~\*]*$');
    final lastMatch = decoratedRegex.firstMatch(lastLine);
    if (lastMatch != null) {
      return int.tryParse(lastMatch.group(1)!);
    }
    final firstMatch = decoratedRegex.firstMatch(firstLine);
    if (firstMatch != null) {
      return int.tryParse(firstMatch.group(1)!);
    }

    // Strategy 3: Number at the very end of last line or start of first line
    final trailingRegex = RegExp(r'\b(\d{1,4})\s*$');
    final trailingMatch = trailingRegex.firstMatch(lastLine);
    if (trailingMatch != null && lastLine.length <= 10) {
      return int.tryParse(trailingMatch.group(1)!);
    }
    final leadingRegex = RegExp(r'^\s*(\d{1,4})\b');
    final leadingMatch = leadingRegex.firstMatch(firstLine);
    if (leadingMatch != null && firstLine.length <= 10) {
      return int.tryParse(leadingMatch.group(1)!);
    }

    return null;
  }
}

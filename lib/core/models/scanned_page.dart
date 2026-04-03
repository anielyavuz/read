import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single scanned book page with OCR-extracted text.
class ScannedPage {
  /// Firestore document ID (null for newly created pages).
  final String? id;

  /// Detected page number from OCR, null if not detected.
  final int? pageNumber;

  /// Full recognized text from the image.
  final String extractedText;

  /// Source image file path (local, not persisted to Firestore).
  final String imagePath;

  /// When the page was scanned.
  final DateTime? scannedAt;

  const ScannedPage({
    this.id,
    this.pageNumber,
    required this.extractedText,
    this.imagePath = '',
    this.scannedAt,
  });

  factory ScannedPage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScannedPage(
      id: doc.id,
      pageNumber: data['pageNumber'] as int?,
      extractedText: data['extractedText'] ?? '',
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pageNumber': pageNumber,
      'extractedText': extractedText,
      'scannedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Display label for the page (e.g. "Page 42" or "Page 1" fallback index).
  String displayLabel(int index) {
    if (pageNumber != null) return 'Page $pageNumber';
    return 'Page ${index + 1}';
  }
}

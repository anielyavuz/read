import '../../../core/models/scanned_page.dart';

enum PageScanStatus { initial, capturing, processing, previewReady, error }

class PageScanState {
  final PageScanStatus status;
  final List<String> imagePaths;
  final List<ScannedPage> scannedPages;
  final String? errorMessage;

  const PageScanState({
    this.status = PageScanStatus.initial,
    this.imagePaths = const [],
    this.scannedPages = const [],
    this.errorMessage,
  });

  PageScanState copyWith({
    PageScanStatus? status,
    List<String>? imagePaths,
    List<ScannedPage>? scannedPages,
    String? errorMessage,
  }) {
    return PageScanState(
      status: status ?? this.status,
      imagePaths: imagePaths ?? this.imagePaths,
      scannedPages: scannedPages ?? this.scannedPages,
      errorMessage: errorMessage,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/scan_constants.dart';
import '../../../core/services/page_scanner_service.dart';
import '../../../core/services/scanned_pages_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/page_scan_cubit.dart';
import '../cubit/page_scan_state.dart';

class ScanPagesScreen extends StatelessWidget {
  final String bookId;
  final String bookTitle;

  const ScanPagesScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageScanCubit(scannerService: PageScannerService()),
      child: _ScanPagesBody(bookId: bookId, bookTitle: bookTitle),
    );
  }
}

class _ScanPagesBody extends StatelessWidget {
  final String bookId;
  final String bookTitle;

  const _ScanPagesBody({required this.bookId, required this.bookTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          l10n.scanPages,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<PageScanCubit, PageScanState>(
        builder: (context, state) {
          if (state.status == PageScanStatus.processing) {
            return _buildProcessing(l10n);
          }
          if (state.status == PageScanStatus.previewReady) {
            return _buildPreview(context, state, l10n);
          }
          return _buildCapture(context, state, l10n);
        },
      ),
    );
  }

  Widget _buildProcessing(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            l10n.scanProcessing,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapture(
    BuildContext context,
    PageScanState state,
    AppLocalizations l10n,
  ) {
    final cubit = context.read<PageScanCubit>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book title
          Text(
            bookTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.scanPagesCount(state.imagePaths.length, maxScanPages),
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Image grid
          if (state.imagePaths.isNotEmpty) ...[
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.imagePaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(state.imagePaths[i]),
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => cubit.removeImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Error message
          if (state.status == PageScanStatus.error &&
              state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Source buttons
          if (cubit.remainingSlots > 0) ...[
            _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: l10n.takePhoto,
              onTap: cubit.pickFromCamera,
            ),
            const SizedBox(height: 12),
            _SourceButton(
              icon: Icons.photo_library_rounded,
              label: l10n.pickFromGallery,
              onTap: cubit.pickFromGallery,
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.scanMaxReached(maxScanPages),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.amber),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Process button
          if (state.imagePaths.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cubit.processAllImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.scanStartOcr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    PageScanState state,
    AppLocalizations l10n,
  ) {
    final cubit = context.read<PageScanCubit>();
    final pages = state.scannedPages;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: pages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final page = pages[i];
              final title = page.pageNumber != null
                  ? l10n.scanPageNumber(page.pageNumber!)
                  : l10n.scanPageUnknown;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: page.pageNumber != null
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.textMuted.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: page.pageNumber != null
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(page.imagePath),
                            width: 36,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (page.extractedText.isEmpty)
                      Text(
                        l10n.scanNoText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      Text(
                        page.extractedText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom buttons
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            border: Border(
              top: BorderSide(
                color: AppColors.textMuted.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              if (cubit.remainingSlots > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => cubit.reset(),
                    icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                    label: Text(l10n.scanMore),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              if (cubit.remainingSlots > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _saveAndClose(context, state, l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.scanDone,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Save scanned pages to Firestore and close.
  Future<void> _saveAndClose(
    BuildContext context,
    PageScanState state,
    AppLocalizations l10n,
  ) async {
    if (bookId.isEmpty || state.scannedPages.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final validPages =
        state.scannedPages.where((p) => p.extractedText.isNotEmpty).toList();
    if (validPages.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final service = getIt<ScannedPagesService>();
      await service.savePages(bookId, validPages);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pagesSaved),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/system_info_service.dart';
import '../../../core/services/service_locator.dart';
import '../cubit/book_search_cubit.dart';
import '../cubit/book_search_state.dart';
import '../../../l10n/generated/app_localizations.dart';

class BookSearchScreen extends StatelessWidget {
  const BookSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookSearchCubit(
        googleBooksService: getIt<GoogleBooksService>(),
        libraryService: getIt<BookLibraryService>(),
        systemInfoService: getIt<SystemInfoService>(),
      ),
      child: const _BookAddContent(),
    );
  }
}

class _BookAddContent extends StatefulWidget {
  const _BookAddContent();

  @override
  State<_BookAddContent> createState() => _BookAddContentState();
}

class _BookAddContentState extends State<_BookAddContent> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  String _selectedStatus = 'reading';
  String? _coverBase64;
  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
      (int.tryParse(_pageCtrl.text.trim()) ?? 0) > 0 &&
      !_isSaving;

  Future<void> _pickCoverImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 400,
      maxHeight: 600,
    );
    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();
    setState(() {
      _coverBase64 = base64Encode(bytes);
    });
  }

  void _showCoverOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: Text(l10n.scanBookCover,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickCoverImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: Text(l10n.changeCoverPhoto,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickCoverImage(ImageSource.gallery);
              },
            ),
            if (_coverBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text(l10n.removeCustomCover,
                    style: const TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _coverBase64 = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCameraScan() async {
    final cubit = context.read<BookSearchCubit>();
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return;

    setState(() => _isScanning = true);

    await cubit.scanBookCover(photo.path);

    final scanStatus = cubit.state.coverScanStatus;
    final scanResult = cubit.state.coverScanResult;

    if (scanStatus == CoverScanStatus.success && scanResult != null) {
      if (scanResult.title != null && scanResult.title!.isNotEmpty) {
        _titleCtrl.text = scanResult.title!;
      }
      if (scanResult.author != null && scanResult.author!.isNotEmpty) {
        _authorCtrl.text = scanResult.author!;
      }
      if (scanResult.pageCount != null && scanResult.pageCount! > 0) {
        _pageCtrl.text = scanResult.pageCount.toString();
      }
    } else if (scanStatus == CoverScanStatus.notABook) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bookCoverNotDetected),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bookCoverScanError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    cubit.resetCoverScan();
    setState(() => _isScanning = false);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSaving = true);

    final cubit = context.read<BookSearchCubit>();
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    final pages = int.tryParse(_pageCtrl.text.trim()) ?? 0;
    final l10n = AppLocalizations.of(context)!;

    final book = await cubit.addManualBook(
      title: title,
      author: author.isNotEmpty ? author : 'Unknown',
      pageCount: pages,
      status: _selectedStatus,
    );

    if (book != null && _coverBase64 != null) {
      // Save custom cover after book is added
      await getIt<BookLibraryService>().updateCustomCover(
        bookId: book.id,
        base64Image: _coverBase64,
      );
    }

    setState(() => _isSaving = false);

    if (book != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookAdded),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final isSelected = value == _selectedStatus;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          l10n.addBookManually,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _handleCameraScan,
            tooltip: l10n.scanBookCover,
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover photo (optional)
            Center(
              child: GestureDetector(
                onTap: _showCoverOptions,
                child: _coverBase64 != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(_coverBase64!),
                              width: 100,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.tapToChangeCover,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: AppColors.textMuted,
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.addCoverPhoto,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Book title (required)
            Text(
              '${l10n.bookTitle} *',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildField(_titleCtrl, l10n.bookTitle),
            const SizedBox(height: 16),

            // Author (optional)
            Text(
              l10n.authorName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildField(_authorCtrl, l10n.authorName),
            const SizedBox(height: 16),

            // Page count (required)
            Text(
              '${l10n.pageCountLabel} *',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildField(
              _pageCtrl,
              l10n.pageCountLabel,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Status selector
            Text(
              l10n.addStatus,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusChip(l10n.currentlyReading, 'reading'),
                const SizedBox(width: 8),
                _statusChip(l10n.wantToRead, 'tbr'),
              ],
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.3),
                  disabledForegroundColor:
                      AppColors.textMuted.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.addToLibrary,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/book.dart';
import '../../../l10n/generated/app_localizations.dart';

class SearchResultCard extends StatelessWidget {
  final Book book;
  final void Function(Book book, String status, {int? currentPage}) onAdd;

  const SearchResultCard({
    super.key,
    required this.book,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Book cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 75,
              child: book.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.backgroundDark,
                        child: const Icon(
                          Icons.book,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundDark,
                        child: const Icon(
                          Icons.book,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.backgroundDark,
                      child: const Icon(
                        Icons.book,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Book info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.authors.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                if (book.pageCount > 0)
                  Text(
                    l10n.pagesCount(book.pageCount),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          // Add button
          IconButton(
            onPressed: () => _showStatusPicker(context),
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _StatusPickerSheet(
          book: book,
          onAdd: onAdd,
          l10n: l10n,
        );
      },
    );
  }
}

class _StatusPickerSheet extends StatefulWidget {
  final Book book;
  final void Function(Book book, String status, {int? currentPage}) onAdd;
  final AppLocalizations l10n;

  const _StatusPickerSheet({
    required this.book,
    required this.onAdd,
    required this.l10n,
  });

  @override
  State<_StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<_StatusPickerSheet> {
  bool _showPageInput = false;
  final _pageCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _confirmReading() {
    final page = int.tryParse(_pageCtrl.text.trim()) ?? 1;
    final clampedPage = page.clamp(1, widget.book.pageCount > 0 ? widget.book.pageCount : 99999);
    Navigator.pop(context);
    widget.onAdd(widget.book, 'reading', currentPage: clampedPage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.l10n.bookAdded),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.l10n.addToLibrary,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (!_showPageInput) ...[
              // Currently Reading
              ListTile(
                leading: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  widget.l10n.currentlyReading,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  setState(() => _showPageInput = true);
                },
              ),
              // Want to Read
              ListTile(
                leading: const Icon(
                  Icons.bookmark_outline,
                  color: AppColors.amber,
                ),
                title: Text(
                  widget.l10n.wantToRead,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onAdd(widget.book, 'tbr');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.l10n.bookAdded),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],

            // Page input for "Currently Reading"
            if (_showPageInput) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      widget.l10n.currentPageQuestion,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _pageCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.backgroundDark,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixText: widget.book.pageCount > 0
                              ? '/ ${widget.book.pageCount}'
                              : null,
                          suffixStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        onSubmitted: (_) => _confirmReading(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _confirmReading,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.l10n.addToLibrary,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/book_cover_image.dart';
import '../../../core/models/user_book.dart';
import '../../../l10n/generated/app_localizations.dart';

class BookSelectorSheet extends StatelessWidget {
  final List<UserBook> books;
  final void Function(String bookId, String title) onSelect;

  const BookSelectorSheet({
    super.key,
    required this.books,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.selectBookForFocus,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (books.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noBookSelected,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: books.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.dividerDark,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final book = books[index];
                  final progressPercent =
                      (book.progressPercent * 100).toStringAsFixed(0);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: BookCoverImage(
                      customCoverBase64: book.customCoverBase64,
                      coverUrl: book.coverUrl,
                      width: 40,
                      height: 56,
                      borderRadius: 6,
                      iconSize: 20,
                    ),
                    title: Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book.authors.isNotEmpty)
                          Text(
                            book.authors.join(', '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedProgressBar(
                                value: book.progressPercent,
                                height: 3,
                                gradientColors: const [
                                  AppColors.primary,
                                  Color(0xFF22C55E),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$progressPercent%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      onSelect(book.bookId, book.title);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/book_cover_image.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/models/user_book.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/library_cubit.dart';

class BookCard extends StatelessWidget {
  final UserBook userBook;

  const BookCard({super.key, required this.userBook});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GameButton(
        onTap: () async {
          await context.push('/book/${userBook.bookId}');
          if (context.mounted) {
            context.read<LibraryCubit>().loadLibrary();
          }
        },
        color: AppColors.surfaceDark,
        shadowColor: AppColors.primary.withValues(alpha: 0.25),
        shadowHeight: 4,
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Book cover
                BookCoverImage(
                  customCoverBase64: userBook.customCoverBase64,
                  coverUrl: userBook.coverUrl,
                  width: 60,
                  height: 90,
                  borderRadius: 8,
                  iconSize: 28,
                ),
                const SizedBox(width: 12),
                // Book info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userBook.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userBook.authors.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (userBook.status == 'reading') ...[
                        AnimatedProgressBar(
                          value: userBook.progressPercent,
                          height: 6,
                          gradientColors: const [
                            AppColors.primary,
                            Color(0xFF22C55E),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.pagesOf(userBook.currentPage, userBook.totalPages),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (userBook.status == 'finished')
                        Text(
                          l10n.completed,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


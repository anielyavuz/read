import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/reader_profile.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/reader_profile_service.dart';
import '../../../core/services/reader_profile_repository.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../cubit/reader_profile_cubit.dart';
import '../cubit/reader_profile_state.dart';

class ReaderProfileDetailSheet extends StatelessWidget {
  final ReaderProfile profile;

  const ReaderProfileDetailSheet({
    super.key,
    required this.profile,
  });

  static void show(BuildContext context, ReaderProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BlocProvider(
        create: (_) => ReaderProfileCubit(
          service: getIt<ReaderProfileService>(),
          repository: getIt<ReaderProfileRepository>(),
          googleBooksService: getIt<GoogleBooksService>(),
          bookLibraryService: getIt<BookLibraryService>(),
        )..loadExistingProfile(),
        child: ReaderProfileDetailSheet(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ReaderProfileCubit, ReaderProfileState>(
      builder: (context, state) {
        final currentProfile = state.profile ?? profile;
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(child: MascotWidget(size: 60)),
                  const SizedBox(height: 16),
                  // Archetype name
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ).createShader(bounds),
                      child: Text(
                        currentProfile.archetypeName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      currentProfile.archetypeDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 24),

                  // Preferred genres
                  Text(
                    l10n.preferredGenresTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentProfile.preferredGenres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Reading tone
                  Text(
                    l10n.readingToneTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentProfile.preferredTone,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reading DNA
                  Text(
                    l10n.readingDnaTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                      l10n.characterFocusLabel,
                      currentProfile.profileScore.characterFocus,
                      AppColors.primary),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                      l10n.plotFocusLabel,
                      currentProfile.profileScore.plotFocus,
                      AppColors.success),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                      l10n.atmosphereFocusLabel,
                      currentProfile.profileScore.atmosphereFocus,
                      AppColors.amber),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                      l10n.paceFocusLabel,
                      currentProfile.profileScore.paceSlow,
                      const Color(0xFF06B6D4)),
                  const SizedBox(height: 24),

                  // Recommended books with action buttons
                  if (currentProfile.recommendedBooks.isNotEmpty) ...[
                    Text(
                      l10n.recommendedBooksTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...currentProfile.recommendedBooks
                        .where((book) => !state.bookActions.containsKey(book.title))
                        .map((book) {
                      return _buildBookTile(context, book, state, l10n);
                    }),
                    const SizedBox(height: 8),
                    _buildLoadMoreButton(context, state, l10n),
                    const SizedBox(height: 16),
                  ],

                  // Avoided genres
                  if (currentProfile.avoidGenres.isNotEmpty) ...[
                    Text(
                      l10n.avoidedGenresTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentProfile.avoidGenres.map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/reader-profile-quiz');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.updateProfileButton,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required AppLocalizations l10n,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.confirmCancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirmYes, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  Widget _buildBookTile(
    BuildContext context,
    RecommendedBook book,
    ReaderProfileState state,
    AppLocalizations l10n,
  ) {
    final action = state.bookActions[book.title];
    final hasAction = action != null;

    Color actionColor() {
      switch (action) {
        case 'finished':
          return AppColors.success;
        case 'not_interested':
          return AppColors.error;
        default:
          return AppColors.primary;
      }
    }

    IconData actionIcon() {
      switch (action) {
        case 'finished':
          return Icons.check_circle;
        case 'not_interested':
          return Icons.not_interested;
        default:
          return Icons.bookmark;
      }
    }

    String actionLabel() {
      switch (action) {
        case 'finished':
          return l10n.bookMarkedAsRead;
        case 'not_interested':
          return l10n.bookMarkedAsNotInterested;
        default:
          return l10n.bookMarkedAsWillRead;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: action == 'not_interested' ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: hasAction
                ? Border.all(
                    color: actionColor().withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (hasAction ? actionColor() : AppColors.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasAction ? actionIcon() : Icons.menu_book,
                      color: hasAction ? actionColor() : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          book.author,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                book.reason,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!hasAction) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () => _showConfirmDialog(
                            context: context,
                            title: l10n.bookActionRead,
                            message: l10n.confirmBookRead(book.title),
                            l10n: l10n,
                            onConfirm: () {
                              context.read<ReaderProfileCubit>().saveBookToLibrary(
                                    book.title, book.author, 'finished');
                            },
                          ),
                          icon: const Icon(Icons.check, size: 15),
                          label: Text(l10n.bookActionRead,
                              style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: BorderSide(
                                color: AppColors.success.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () => _showConfirmDialog(
                            context: context,
                            title: l10n.bookActionWillRead,
                            message: l10n.confirmBookWillRead(book.title),
                            l10n: l10n,
                            onConfirm: () {
                              context.read<ReaderProfileCubit>().saveBookToLibrary(
                                    book.title, book.author, 'tbr');
                            },
                          ),
                          icon: const Icon(Icons.bookmark_add_outlined, size: 15),
                          label: Text(l10n.bookActionWillRead,
                              style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () => _showConfirmDialog(
                            context: context,
                            title: l10n.bookActionNotInterested,
                            message: l10n.confirmBookNotInterested(book.title),
                            l10n: l10n,
                            onConfirm: () {
                              context.read<ReaderProfileCubit>()
                                  .markNotInterested(book.title);
                            },
                          ),
                          icon: const Icon(Icons.not_interested, size: 15),
                          label: Text(l10n.bookActionNotInterested,
                              style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(actionIcon(), size: 14, color: actionColor()),
                    const SizedBox(width: 4),
                    Text(
                      actionLabel(),
                      style: TextStyle(
                        color: actionColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(
    BuildContext context,
    ReaderProfileState state,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: state.loadingMoreRecs
            ? null
            : () {
                context.read<ReaderProfileCubit>().loadMoreRecommendations();
              },
        icon: state.loadingMoreRecs
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome, size: 18),
        label: Text(
          state.loadingMoreRecs
              ? l10n.loadingMoreRecs
              : l10n.loadMoreRecsButton,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, Color color) {
    final clampedValue = value.clamp(0, 100);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$clampedValue%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedValue / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

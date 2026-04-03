import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_book.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';
import '../widgets/book_card.dart';

/// Library tab — cubit is provided by ShellScreen, not created here.
class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          children: [
            // AppBar-like header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.library,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await context.push('/book-search');
                      if (context.mounted) {
                        context.read<LibraryCubit>().loadLibrary();
                      }
                    },
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textPrimary,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(text: l10n.reading),
                  Tab(text: l10n.finished),
                  Tab(text: l10n.toBeRead),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tag filter chips
            BlocBuilder<LibraryCubit, LibraryState>(
              buildWhen: (prev, curr) =>
                  prev.allTags != curr.allTags ||
                  prev.selectedTag != curr.selectedTag,
              builder: (context, state) {
                if (state.allTags.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: l10n.allBooks,
                        isSelected: state.selectedTag == null,
                        onTap: () => context.read<LibraryCubit>().filterByTag(null),
                      ),
                      const SizedBox(width: 8),
                      ...state.allTags.map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: tag,
                              isSelected: state.selectedTag == tag,
                              onTap: () => context.read<LibraryCubit>().filterByTag(tag),
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Tab content
            Expanded(
              child: BlocBuilder<LibraryCubit, LibraryState>(
                builder: (context, state) {
                  if (state.status == LibraryStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (state.status == LibraryStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage ?? l10n.somethingWentWrong,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                context.read<LibraryCubit>().loadLibrary(),
                            child: Text(
                              l10n.retry,
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    children: [
                      _buildBookList(
                        books: state.filteredReadingBooks,
                        emptyIconWidget: AnimatedEmoji(AnimatedEmojis.nerdFace, size: 48),
                        emptyMessage: l10n.emptyReading,
                      ),
                      _buildBookList(
                        books: state.filteredFinishedBooks,
                        emptyIconWidget: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 48),
                        emptyMessage: l10n.emptyFinished,
                      ),
                      _buildTbrList(
                        context: context,
                        books: state.filteredTbrBooks,
                        emptyIconWidget: AnimatedEmoji(AnimatedEmojis.sparkles, size: 48),
                        emptyMessage: l10n.emptyTbr,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList({
    required List books,
    required Widget emptyIconWidget,
    required String emptyMessage,
  }) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            emptyIconWidget,
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return BookCard(userBook: books[index]);
      },
    );
  }

  Widget _buildTbrList({
    required BuildContext context,
    required List<UserBook> books,
    required Widget emptyIconWidget,
    required String emptyMessage,
  }) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            emptyIconWidget,
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              child: child,
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        context.read<LibraryCubit>().reorderTbrBooks(oldIndex, newIndex);
      },
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Padding(
          key: ValueKey(book.bookId),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Dismissible(
            key: ValueKey('dismiss_${book.bookId}'),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  title: Text(
                    l10n.startReading,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    l10n.startReadingConfirm(book.title),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        l10n.confirm,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ) ?? false;
            },
            onDismissed: (_) {
              context.read<LibraryCubit>().startReading(book.bookId);
            },
            background: Container(
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.startReading,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                BookCard(userBook: book),
                // Order number badge
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Drag handle
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 4,
                  child: Center(
                    child: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

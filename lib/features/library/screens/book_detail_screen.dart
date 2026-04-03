import 'dart:convert';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/book_note.dart';
import '../../../core/models/user_book.dart';
import '../../../core/services/book_note_service.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/constants/badge_definitions.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/widgets/book_cover_image.dart';
import '../../../features/profile/utils/badge_l10n_helper.dart';
import '../../focus/cubit/book_notes_cubit.dart';
import '../cubit/book_detail_cubit.dart';
import '../cubit/book_detail_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/page_update_sheet.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<BookDetailCubit>()..loadBook(bookId),
        ),
        BlocProvider(
          create: (_) => BookNotesCubit(noteService: getIt<BookNoteService>()),
        ),
      ],
      child: _BookDetailContent(bookId: bookId),
    );
  }
}

class _BookDetailContent extends StatelessWidget {
  final String bookId;
  const _BookDetailContent({required this.bookId});

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
          l10n.bookDetails,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showRemoveConfirmDialog(context, l10n),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ),
        ],
      ),
      body: BlocListener<BookDetailCubit, BookDetailState>(
        listenWhen: (prev, curr) =>
            prev.coverUploadStatus != curr.coverUploadStatus &&
            (curr.coverUploadStatus == CoverUploadStatus.success ||
             curr.coverUploadStatus == CoverUploadStatus.error),
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          if (state.coverUploadStatus == CoverUploadStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.coverPhotoUpdated,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.coverPhotoError,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: BlocListener<BookDetailCubit, BookDetailState>(
        listenWhen: (prev, curr) => curr.status == BookDetailStatus.removed,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.bookRemoved,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        },
        child: BlocListener<BookDetailCubit, BookDetailState>(
        listenWhen: (prev, curr) =>
            curr.newlyEarnedBadgeIds.isNotEmpty &&
            prev.newlyEarnedBadgeIds != curr.newlyEarnedBadgeIds,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final badgeNames = state.newlyEarnedBadgeIds.map((id) {
            final def = allBadges.where((b) => b.id == id).firstOrNull;
            if (def == null) return id;
            return '${def.icon} ${resolveBadgeL10n(l10n, def.nameKey)}';
          }).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.newBadgeEarned} $badgeNames',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.amber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        child: BlocListener<BookDetailCubit, BookDetailState>(
        listenWhen: (prev, curr) => curr.lastXpAwarded > 0 && prev.lastXpAwarded != curr.lastXpAwarded,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.xpEarnedToast(state.lastXpAwarded),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: BlocBuilder<BookDetailCubit, BookDetailState>(
        builder: (context, state) {
          if (state.status == BookDetailStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state.status == BookDetailStatus.error) {
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
                ],
              ),
            );
          }

          final userBook = state.userBook;
          final bookInfo = state.bookInfo;

          if (userBook == null) {
            return Center(
              child: Text(
                l10n.bookNotFound,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            );
          }

          final coverUrl = bookInfo?.coverUrl ?? userBook.coverUrl;
          final customCover = userBook.customCoverBase64;
          final title = bookInfo?.title ?? userBook.title;
          final authors = bookInfo?.authors ?? userBook.authors;
          final description = bookInfo?.description;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Book cover with edit overlay
                GestureDetector(
                  onTap: () => _showCoverOptionsSheet(
                    context,
                    l10n,
                    hasCustomCover: customCover != null && customCover.isNotEmpty,
                  ),
                  child: Stack(
                    children: [
                      BookCoverImage(
                        customCoverBase64: customCover,
                        coverUrl: coverUrl,
                        width: 135,
                        height: 200,
                        borderRadius: 12,
                        iconSize: 40,
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: state.coverUploadStatus == CoverUploadStatus.uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Authors
                Text(
                  authors.join(', '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                // Page count
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.pagesCount(userBook.totalPages),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (userBook.status == 'reading' ||
                        userBook.status == 'tbr')
                      IconButton(
                        onPressed: () => _showEditTotalPagesDialog(
                          context,
                          l10n,
                          userBook.totalPages,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        padding: const EdgeInsets.only(left: 4),
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tags section
                _TagsSection(
                  tags: userBook.tags,
                  allUserTags: state.allUserTags,
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.dividerDark, height: 1),
                const SizedBox(height: 20),
                // Progress & Notes tabbed section
                if (userBook.status == 'reading' ||
                    userBook.status == 'finished') ...[
                  _ProgressNotesSection(
                    bookId: bookId,
                    userBook: userBook,
                    state: state,
                  ),
                  const SizedBox(height: 20),
                ],
                // Remove from Library button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: state.status == BookDetailStatus.updating
                        ? null
                        : () => _showRemoveConfirmDialog(context, l10n),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      l10n.removeFromLibrary,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                if (description != null && description.isNotEmpty) ...[
                  const Divider(color: AppColors.dividerDark, height: 1),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.descriptionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ExpandableDescription(description: _stripHtmlTags(description)),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
      ),
      ),
      ),
      ),
    );
  }
}

void _showCoverOptionsSheet(
  BuildContext context,
  AppLocalizations l10n, {
  required bool hasCustomCover,
}) {
  final cubit = context.read<BookDetailCubit>();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              l10n.changeCoverPhoto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                l10n.takePhoto,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                cubit.uploadCustomCover(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                l10n.pickFromGallery,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                cubit.uploadCustomCover(ImageSource.gallery);
              },
            ),
            if (hasCustomCover)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n.removeCustomCover,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  cubit.removeCustomCover();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

void _showRemoveConfirmDialog(BuildContext context, AppLocalizations l10n) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        l10n.removeBookConfirmTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        l10n.removeBookConfirmMessage,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<BookDetailCubit>().removeFromLibrary();
          },
          child: Text(
            l10n.confirm,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showFinishConfirmDialog(BuildContext context, AppLocalizations l10n) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        l10n.finishBookConfirmTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        l10n.finishBookConfirmMessage,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Haptics.success();
            context.read<BookDetailCubit>().markAsFinished();
          },
          child: Text(
            l10n.confirm,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showEditTotalPagesDialog(
  BuildContext context,
  AppLocalizations l10n,
  int currentTotalPages,
) {
  final controller = TextEditingController(text: currentTotalPages.toString());
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        l10n.editTotalPages,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: l10n.totalPagesLabel,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.backgroundDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            final newTotal = int.tryParse(controller.text);
            if (newTotal != null && newTotal > 0) {
              Navigator.pop(ctx);
              context.read<BookDetailCubit>().updateTotalPages(newTotal);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.totalPagesUpdated,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Text(
            l10n.save,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Tabbed section showing Progress and Notes side by side.
class _ProgressNotesSection extends StatefulWidget {
  final String bookId;
  final UserBook userBook;
  final BookDetailState state;

  const _ProgressNotesSection({
    required this.bookId,
    required this.userBook,
    required this.state,
  });

  @override
  State<_ProgressNotesSection> createState() => _ProgressNotesSectionState();
}

class _ProgressNotesSectionState extends State<_ProgressNotesSection> {
  int _selectedTab = 0; // 0 = Progress, 1 = Notes

  @override
  void initState() {
    super.initState();
    // Pre-load notes count
    context.read<BookNotesCubit>().loadNotes(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Tab selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTab(
                index: 0,
                icon: Icons.show_chart_rounded,
                label: l10n.progress,
              ),
              _buildTab(
                index: 1,
                icon: Icons.sticky_note_2_rounded,
                label: l10n.myNotes,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selectedTab == 0
              ? _ProgressContent(
                  key: const ValueKey('progress'),
                  userBook: widget.userBook,
                  state: widget.state,
                )
              : _NotesContent(
                  key: const ValueKey('notes'),
                  bookId: widget.bookId,
                ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              // Notes count badge
              if (index == 1)
                BlocBuilder<BookNotesCubit, BookNotesState>(
                  builder: (context, notesState) {
                    if (notesState.notes.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.textMuted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${notesState.notes.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress tab content — circular progress + action buttons.
class _ProgressContent extends StatelessWidget {
  final UserBook userBook;
  final BookDetailState state;

  const _ProgressContent({
    super.key,
    required this.userBook,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progressPercent = userBook.progressPercent;
    final percentText = (progressPercent * 100).round();

    return Column(
      children: [
        // Progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progressPercent,
                      strokeWidth: 8,
                      backgroundColor: AppColors.backgroundDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '$percentText%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.pagesOf(userBook.currentPage, userBook.totalPages),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Update Progress button
        if (userBook.status == 'reading')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state.status == BookDetailStatus.updating
                  ? null
                  : () {
                      final cubit = context.read<BookDetailCubit>();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surfaceDark,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => PageUpdateSheet(
                          currentPage: userBook.currentPage,
                          totalPages: userBook.totalPages,
                          onSave: (page) => cubit.updatePage(page),
                        ),
                      );
                    },
              icon: const Icon(Icons.edit, size: 18),
              label: Text(
                l10n.updateProgress,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        // Mark as Finished button
        if (userBook.status == 'reading') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: state.status == BookDetailStatus.updating
                  ? null
                  : () => _showFinishConfirmDialog(context, l10n),
              icon: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 18),
              label: Text(
                l10n.markAsFinished,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        // Continue Reading button (revert from finished)
        if (userBook.status == 'finished') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: state.status == BookDetailStatus.updating
                  ? null
                  : () {
                      context.read<BookDetailCubit>().markAsReading();
                    },
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(
                l10n.continueReading,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Notes tab content — list of saved notes for this book.
class _NotesContent extends StatelessWidget {
  final String bookId;

  const _NotesContent({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BookNotesCubit, BookNotesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state.notes.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 40,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.noNotesForBook,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noNotesForBookDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notes count header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.notesCount(state.notes.length),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Notes list
            ...state.notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DetailNoteCard(
                    note: note,
                    onDelete: () {
                      if (note.id != null) {
                        context.read<BookNotesCubit>().deleteNote(note.id!);
                      }
                    },
                  ),
                )),
          ],
        );
      },
    );
  }
}

/// Note card for book detail screen (read-only view).
class _DetailNoteCard extends StatelessWidget {
  final BookNote note;
  final VoidCallback onDelete;

  const _DetailNoteCard({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              if (note.pageNumber != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    l10n.pageN(note.pageNumber!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (note.hasImage && note.pageNumber != null)
                const SizedBox(width: 5),
              if (note.hasImage)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_rounded,
                          size: 10, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        l10n.photo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (note.createdAt != null)
                Text(
                  _formatDate(note.createdAt!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _confirmDelete(context, l10n),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          // Image
          if (note.hasImage) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _showFullImage(context, note.imageBase64!),
                child: Image.memory(
                  base64Decode(note.imageBase64!),
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    color: AppColors.backgroundDark,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Text
          if (note.hasContent) ...[
            const SizedBox(height: 8),
            Text(
              note.content!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m · $h:$min';
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteNote,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.deleteNoteConfirm,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
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

/// Tags section — displays current tags as chips + add button.
class _TagsSection extends StatelessWidget {
  final List<String> tags;
  final List<String> allUserTags;

  const _TagsSection({
    required this.tags,
    required this.allUserTags,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Icon(
              Icons.label_outline_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.tags,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Tags wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => _TagChip(
                  label: tag,
                  onRemove: () {
                    final newTags = List<String>.from(tags)..remove(tag);
                    context.read<BookDetailCubit>().updateTags(newTags);
                  },
                )),
            // Add tag button
            GestureDetector(
              onTap: () => _showTagSheet(context, l10n, tags, allUserTags),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.addTag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTagSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<String> currentTags,
    List<String> allTags,
  ) {
    final cubit = context.read<BookDetailCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TagManagementSheet(
        currentTags: currentTags,
        allUserTags: allTags,
        onSave: (tags) => cubit.updateTags(tags),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for managing tags — select existing or create new.
class _TagManagementSheet extends StatefulWidget {
  final List<String> currentTags;
  final List<String> allUserTags;
  final ValueChanged<List<String>> onSave;

  const _TagManagementSheet({
    required this.currentTags,
    required this.allUserTags,
    required this.onSave,
  });

  @override
  State<_TagManagementSheet> createState() => _TagManagementSheetState();
}

class _TagManagementSheetState extends State<_TagManagementSheet> {
  late List<String> _selectedTags;
  late List<String> _availableTags;
  final _newTagController = TextEditingController();
  bool _showNewTagField = false;

  // Default suggested tags (l10n keys resolved in build)
  static const _defaultTagKeys = [
    'Fiction',
    'Self-Help',
    'Non-Fiction',
    'Romance',
    'Mystery',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List<String>.from(widget.currentTags);
    // Merge allUserTags + defaults, deduplicated
    _availableTags = {...widget.allUserTags, ..._defaultTagKeys}.toList()..sort();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Resolve default tag display names
    final defaultTagNames = {
      'Fiction': l10n.defaultTagFiction,
      'Self-Help': l10n.defaultTagSelfHelp,
      'Non-Fiction': l10n.defaultTagNonFiction,
      'Romance': l10n.defaultTagRomance,
      'Mystery': l10n.defaultTagMystery,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            l10n.manageTags,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Available tags as selectable chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              final displayName = defaultTagNames[tag] ?? tag;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // New tag input
          if (_showNewTagField)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.newTagHint,
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onSubmitted: (_) => _addNewTag(l10n),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addNewTag(l10n),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showNewTagField = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.newTag,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_selectedTags);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewTag(AppLocalizations l10n) {
    final tagName = _newTagController.text.trim();
    if (tagName.isEmpty) return;
    if (_availableTags.contains(tagName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tagAlreadyExists),
          backgroundColor: AppColors.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() {
      _availableTags.add(tagName);
      _availableTags.sort();
      _selectedTags.add(tagName);
      _newTagController.clear();
      _showNewTagField = false;
    });
  }
}

String _stripHtmlTags(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

class _ExpandableDescription extends StatefulWidget {
  final String description;

  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() =>
      _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        if (widget.description.length > 200)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _expanded ? l10n.showLess : l10n.readMore,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

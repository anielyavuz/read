import 'package:animated_emoji/animated_emoji.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_book.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/constants/badge_definitions.dart';
import '../../../features/profile/utils/badge_l10n_helper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/focus_cubit.dart';
import '../cubit/focus_state.dart';
import '../cubit/book_notes_cubit.dart';
import '../widgets/book_selector_sheet.dart';
import '../widgets/book_notes_sheet.dart';
import '../widgets/timer_display.dart';

/// Focus tab — cubit is provided by ShellScreen, not created here.
class FocusTab extends StatelessWidget {
  const FocusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocBuilder<FocusCubit, FocusState>(
        builder: (context, state) {
          if (state.status == FocusStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? l10n.somethingWentWrong,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<FocusCubit>().loadInitialData(),
                    child: Text(
                      l10n.retry,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Header
                  Text(
                    l10n.focusMode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Book selector (only when idle)
                  if (state.status == FocusStatus.idle) ...[
                    if (state.selectedBookId != null)
                      _SelectedBookCard(
                        bookTitle: state.selectedBookTitle ?? '',
                        currentPage: state.selectedBookCurrentPage,
                        totalPages: state.selectedBookTotalPages,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => BookSelectorSheet(
                              books: context
                                  .read<FocusCubit>()
                                  .state
                                  .readingBooks,
                              onSelect: (bookId, title) {
                                context.read<FocusCubit>().selectBook(
                                  bookId,
                                  title,
                                );
                              },
                            ),
                          );
                        },
                      )
                    else
                      _BookSelector(
                        selectedBookTitle: state.selectedBookTitle,
                        readingBooks: state.readingBooks,
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Selected book label + notes button (when running/paused)
                  if (state.status == FocusStatus.running ||
                      state.status == FocusStatus.paused)
                    if (state.selectedBookTitle != null) ...[
                      Center(
                        child: Text(
                          state.selectedBookTitle!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Notes button
                      if (state.selectedBookId != null)
                        Center(
                          child: _NotesButton(
                            bookId: state.selectedBookId!,
                            bookTitle: state.selectedBookTitle!,
                            currentPage: state.selectedBookCurrentPage,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                  // Timer display
                  if (state.status != FocusStatus.completed)
                    Center(
                      child: TimerDisplay(
                        elapsed: state.elapsed,
                        target: state.targetDuration,
                        isRunning: state.status == FocusStatus.running,
                        ringColor:
                            (state.mode == FocusMode.pomodoro && state.isBreak)
                            ? const Color(0xFF4ADE80)
                            : null,
                      ),
                    ),

                  // Pomodoro phase indicator (under timer, when running)
                  if (state.mode == FocusMode.pomodoro &&
                      (state.status == FocusStatus.running ||
                          state.status == FocusStatus.paused))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedEmoji(
                              state.isBreak
                                  ? AnimatedEmojis.hotBeverage
                                  : AnimatedEmojis.fire,
                              size: 16,
                              repeat: false,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state.isBreak
                                  ? l10n.breakPhase
                                  : '${l10n.workPhase} · ${l10n.pomodoroRound(state.pomodoroCount + 1)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: state.isBreak
                                    ? const Color(0xFF4ADE80)
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Mode selector (only when idle)
                  if (state.status == FocusStatus.idle) ...[
                    _ModeSelector(),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons based on status
                  if (state.status == FocusStatus.idle)
                    _StartButton()
                  else if (state.status == FocusStatus.running)
                    _RunningButtons()
                  else if (state.status == FocusStatus.paused)
                    _PausedButtons()
                  else if (state.status == FocusStatus.saving)
                    _SavingView()
                  else if (state.status == FocusStatus.bookFinished)
                    _BookFinishedView(state: state)
                  else if (state.status == FocusStatus.completed)
                    _CompletedView(state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookSelector extends StatelessWidget {
  final String? selectedBookTitle;
  final List<UserBook> readingBooks;

  const _BookSelector({this.selectedBookTitle, this.readingBooks = const []});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<FocusCubit>();

    return GestureDetector(
      onTap: () {
        if (readingBooks.isEmpty) {
          // No reading books — navigate to library to add one
          context.go('/library');
          return;
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => BookSelectorSheet(
            books: readingBooks,
            onSelect: (bookId, title) {
              cubit.selectBook(bookId, title);
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedBookTitle != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.surfaceDark,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selectedBookTitle != null
                  ? Icons.menu_book_rounded
                  : Icons.add_circle_outline_rounded,
              color: selectedBookTitle != null
                  ? AppColors.primary
                  : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedBookTitle ?? l10n.selectBook,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selectedBookTitle != null
                      ? FontWeight.w500
                      : FontWeight.w400,
                  color: selectedBookTitle != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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

class _StartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Haptics.heavy();
          context.read<FocusCubit>().startTimer();
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          l10n.startFocus,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _RunningButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Haptics.medium();
                context.read<FocusCubit>().pauseTimer();
              },
              icon: const Icon(Icons.pause_rounded, size: 24),
              label: Text(
                l10n.pauseFocus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Haptics.heavy();
                context.read<FocusCubit>().stopTimer();
              },
              icon: const Icon(Icons.stop_rounded, size: 24),
              label: Text(
                l10n.stopFocus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PausedButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Haptics.medium();
                context.read<FocusCubit>().resumeTimer();
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                l10n.resumeFocus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Haptics.heavy();
                context.read<FocusCubit>().stopTimer();
              },
              icon: const Icon(Icons.stop_rounded, size: 24),
              label: Text(
                l10n.stopFocus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.textMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.savingProgress,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.updatingCompetitionStatus,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BookFinishedView extends StatefulWidget {
  final FocusState state;

  const _BookFinishedView({required this.state});

  @override
  State<_BookFinishedView> createState() => _BookFinishedViewState();
}

class _BookFinishedViewState extends State<_BookFinishedView>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookTitle = widget.state.finishedBookTitle ?? '';
    final totalXp = widget.state.finishedBookXp;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            const SizedBox(height: 20),

            // Animated trophy
            ScaleTransition(
              scale: _scaleAnimation,
              child: const AnimatedEmoji(
                AnimatedEmojis.trophy,
                size: 80,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n.bookFinishedTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              l10n.bookFinishedSubtitle,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Book title card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 36,
                    color: AppColors.amber,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bookTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.bookFinishedXpEarned(totalXp),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  ),

                  // Show badges if any
                  if (widget.state.newlyEarnedBadgeIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x14FFFFFF), height: 1),
                    const SizedBox(height: 12),
                    ...widget.state.newlyEarnedBadgeIds.map((id) {
                      final def = allBadges
                          .where((b) => b.id == id)
                          .firstOrNull;
                      if (def == null) return const SizedBox.shrink();
                      final name = resolveBadgeL10n(l10n, def.nameKey);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(def.icon,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Dismiss button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Haptics.success();
                  context.read<FocusCubit>().resetAfterBookFinished();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.bookFinishedDismiss,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.08,
          numberOfParticles: 30,
          maxBlastForce: 30,
          minBlastForce: 10,
          gravity: 0.15,
          colors: const [
            AppColors.primary,
            AppColors.amber,
            Color(0xFF4ADE80),
            Color(0xFF60A5FA),
            Color(0xFFF472B6),
            Color(0xFFA78BFA),
          ],
        ),
      ],
    );
  }
}

class _CompletedView extends StatefulWidget {
  final FocusState state;

  const _CompletedView({required this.state});

  @override
  State<_CompletedView> createState() => _CompletedViewState();
}

class _CompletedViewState extends State<_CompletedView> {
  final _pagesController = TextEditingController();
  late final ConfettiController _confettiController;
  bool _showPageError = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    if (widget.state.newlyEarnedBadgeIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _CompletedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.newlyEarnedBadgeIds.isNotEmpty &&
        oldWidget.state.newlyEarnedBadgeIds.isEmpty) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _pagesController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final durationMinutes = widget.state.elapsed.inMinutes;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            // Session complete header
            const AnimatedEmoji(
              AnimatedEmojis.partyPopper,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.sessionComplete,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Duration row
                  _SummaryRow(
                    icon: Icons.timer_rounded,
                    label: l10n.sessionDuration(durationMinutes),
                  ),
                  if (widget.state.selectedBookId != null) ...[
                    const SizedBox(height: 16),

                    // Current page input
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.whatPageAreYouOn,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (widget.state.selectedBookTotalPages > 0)
                                Text(
                                  '${l10n.previousPage}: ${widget.state.selectedBookCurrentPage} / ${widget.state.selectedBookTotalPages}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: TextField(
                            controller: _pagesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            onChanged: (_) {
                              if (_showPageError) {
                                setState(() => _showPageError = false);
                              }
                            },
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: _showPageError
                                  ? const Color(0x1AEF4444)
                                  : AppColors.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: _showPageError
                                    ? const BorderSide(color: Color(0xFFEF4444))
                                    : BorderSide.none,
                              ),
                              enabledBorder: _showPageError
                                  ? OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                      ),
                                    )
                                  : OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                              hintText:
                                  '${widget.state.selectedBookCurrentPage}',
                              hintStyle: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // XP earned
                  Row(
                    children: [
                      const AnimatedEmoji(
                        AnimatedEmojis.sparkles,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.xpEarned(widget.state.xpEarned),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Badge celebration section
                  if (widget.state.newlyEarnedBadgeIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x14FFFFFF), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AnimatedEmoji(
                          AnimatedEmojis.trophy,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.newBadgeEarned,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.state.newlyEarnedBadgeIds.map((id) {
                      final def = allBadges
                          .where((b) => b.id == id)
                          .firstOrNull;
                      if (def == null) return const SizedBox.shrink();
                      final name = resolveBadgeL10n(l10n, def.nameKey);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              def.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save & Close button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final pageText = _pagesController.text.trim();
                  final newPage = pageText.isNotEmpty
                      ? int.tryParse(pageText) ?? 0
                      : 0;

                  // Validate: if book selected, page input is required
                  if (widget.state.selectedBookId != null && newPage <= 0) {
                    setState(() => _showPageError = true);
                    return;
                  }

                  final cubit = context.read<FocusCubit>();

                  // Warn if no page progress was made
                  if (widget.state.selectedBookId != null &&
                      newPage <= widget.state.selectedBookCurrentPage) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          l10n.noProgressTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        content: Text(
                          l10n.noProgressBody,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: Text(
                              l10n.goBack,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: Text(
                              l10n.endAnyway,
                              style: const TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    cubit.discardSessionProgress();
                    return;
                  }

                  Haptics.success();
                  cubit.saveSessionProgress(newPage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showPageError
                      ? const Color(0xFFEF4444)
                      : AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.saveAndClose,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            AppColors.primary,
            AppColors.amber,
            Color(0xFF4ADE80),
            Color(0xFF60A5FA),
          ],
          numberOfParticles: 20,
        ),
      ],
    );
  }
}

class _SelectedBookCard extends StatelessWidget {
  final String bookTitle;
  final int currentPage;
  final int totalPages;
  final VoidCallback onTap;

  const _SelectedBookCard({
    required this.bookTitle,
    required this.currentPage,
    required this.totalPages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progressPercent = totalPages > 0 ? currentPage / totalPages : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bookTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
            if (totalPages > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.continuingFromPage(currentPage),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedProgressBar(
                value: progressPercent,
                height: 4,
                gradientColors: const [
                  AppColors.primary,
                  Color(0xFF22C55E),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.pagesOf(currentPage, totalPages),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<FocusCubit>();
    final state = context.watch<FocusCubit>().state;
    final isPomodoro = state.mode == FocusMode.pomodoro;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ModeChip(
              label: l10n.freeMode,
              isSelected: !isPomodoro,
              onTap: () {
                cubit.setMode(FocusMode.free);
              },
            ),
            const SizedBox(width: 8),
            _ModeChip(
              label: l10n.pomodoroMode,
              isSelected: isPomodoro,
              onTap: () {
                cubit.setMode(FocusMode.pomodoro);
                cubit.setTargetDuration(const Duration(minutes: 25));
              },
            ),
          ],
        ),
        if (isPomodoro) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showPomodoroInfo(context, l10n),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.pomodoroInfoTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showPomodoroInfo(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.pomodoroInfoTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.pomodoroInfoBody,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          // TextButton(
          //   onPressed: () => Navigator.pop(context),
          //   child: Text(
          //     'OK',
          //     style: const TextStyle(color: AppColors.primary),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _NotesButton extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final int currentPage;

  const _NotesButton({
    required this.bookId,
    required this.bookTitle,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Haptics.light();
        final cubit = context.read<FocusCubit>();
        final wasRunning = cubit.state.status == FocusStatus.running;

        // Pause timer while taking notes
        if (wasRunning) cubit.pauseTimer();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
            value: context.read<BookNotesCubit>(),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.48,
                child: BookNotesSheet(
                  bookId: bookId,
                  bookTitle: bookTitle,
                  currentPage: currentPage,
                ),
              ),
            ),
          ),
        ).then((_) {
          // Resume timer when notes sheet is dismissed
          if (wasRunning && cubit.state.status == FocusStatus.paused) {
            cubit.resumeTimer();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sticky_note_2_rounded,
              size: 16,
              color: AppColors.amber,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.notes,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

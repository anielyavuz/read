import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/system_info_service.dart';
import '../../../core/services/service_locator.dart';
import '../cubit/book_search_cubit.dart';
import '../cubit/book_search_state.dart';
import '../widgets/search_result_card.dart';
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
      child: const _BookSearchContent(),
    );
  }
}

class _BookSearchContent extends StatefulWidget {
  const _BookSearchContent();

  @override
  State<_BookSearchContent> createState() => _BookSearchContentState();
}

class _BookSearchContentState extends State<_BookSearchContent> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          l10n.searchBooks,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              onChanged: (query) {
                context.read<BookSearchCubit>().search(query);
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<BookSearchCubit>().clearSearch();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      )
                    : null,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: BlocBuilder<BookSearchCubit, BookSearchState>(
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(child: _buildResultsArea(context, state, l10n)),
                    // Fixed "Add Manually" button at bottom
                    _buildManualAddButton(context, l10n),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea(
    BuildContext context,
    BookSearchState state,
    AppLocalizations l10n,
  ) {
    switch (state.status) {
      case SearchStatus.initial:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.searchHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );

      case SearchStatus.searching:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );

      case SearchStatus.loaded:
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: state.results.length,
          itemBuilder: (context, index) {
            final book = state.results[index];
            return SearchResultCard(
              book: book,
              onAdd: (book, status, {int? currentPage}) {
                context.read<BookSearchCubit>().addToLibrary(book, status, currentPage: currentPage);
              },
            );
          },
        );

      case SearchStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noResults,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );

      case SearchStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.somethingWentWrong,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildManualAddButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () async {
            await context.push('/book-manual-add');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cantFindBook,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.addManually,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
        ),
      ),
    );
  }
}

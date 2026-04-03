import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({super.key});

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  final Set<String> _selectedGenres = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final genres = _buildGenreList(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  Expanded(
                    child: Text(
                      l10n.appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            _buildProgressDots(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.pickFavoriteGenres,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.genreSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: _buildGenreGrid(genres),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _selectedGenres.isNotEmpty ? _onContinue : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.continueText),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(false),
          const SizedBox(width: 12),
          _dot(true),
          const SizedBox(width: 12),
          _dot(false),
          const SizedBox(width: 12),
          _dot(false),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: active ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  List<_GenreItem> _buildGenreList(AppLocalizations l10n) {
    return [
      _GenreItem('fantasy', l10n.genreFantasy, Icons.auto_awesome, animatedEmoji: AnimatedEmojis.sparkles),
      _GenreItem('romance', l10n.genreRomance, Icons.favorite, animatedEmoji: AnimatedEmojis.redHeart),
      _GenreItem('thriller', l10n.genreThriller, Icons.bolt, animatedEmoji: AnimatedEmojis.fire),
      _GenreItem('sci_fi', l10n.genreSciFi, Icons.rocket_launch, animatedEmoji: AnimatedEmojis.rocket),
      _GenreItem('mystery', l10n.genreMystery, Icons.search, animatedEmoji: AnimatedEmojis.crystalBall),
      _GenreItem('non_fiction', l10n.genreNonFiction, Icons.lightbulb),
      _GenreItem('self_help', l10n.genreSelfHelp, Icons.psychology),
      _GenreItem('history', l10n.genreHistory, Icons.account_balance),
      _GenreItem('horror', l10n.genreHorror, Icons.nights_stay),
      _GenreItem('poetry', l10n.genrePoetry, Icons.edit_note),
      _GenreItem('biography', l10n.genreBiography, Icons.person_outline),
      _GenreItem('young_adult', l10n.genreYoungAdult, Icons.school),
    ];
  }

  Widget _buildGenreGrid(List<_GenreItem> genres) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final isSelected = _selectedGenres.contains(genre.id);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedGenres.remove(genre.id);
              } else {
                _selectedGenres.add(genre.id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (genre.animatedEmoji != null)
                  AnimatedEmoji(genre.animatedEmoji!, size: 28)
                else
                  Icon(
                    genre.icon,
                    size: 28,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                const SizedBox(height: 8),
                Text(
                  genre.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onContinue() async {
    if (_selectedGenres.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genreSelectMin),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    try {
      await getIt<UserProfileService>().saveGenres(_selectedGenres.toList());
    } catch (_) {}

    if (mounted) {
      context.push('/reading-time');
    }
  }
}

class _GenreItem {
  final String id;
  final String label;
  final IconData icon;
  final AnimatedEmojiData? animatedEmoji;

  const _GenreItem(this.id, this.label, this.icon, {this.animatedEmoji});
}

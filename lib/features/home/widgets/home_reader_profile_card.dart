import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/reader_profile.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Compact reader profile card for the home page.
/// Shows archetype name, genre chips, and mini DNA bars in a single row-based layout.
class HomeReaderProfileCard extends StatelessWidget {
  final ReaderProfile? profile;
  final VoidCallback onTap;

  const HomeReaderProfileCard({
    super.key,
    this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return _buildEmpty(context);
    }
    return _buildFilled(context, profile!);
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.readerProfileDiscoverArchetype,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilled(BuildContext context, ReaderProfile rp) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: archetype name + chevron
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rp.archetypeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.readerProfileUpdate,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Genre chips (horizontal scroll)
            if (rp.preferredGenres.isNotEmpty)
              SizedBox(
                height: 22,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rp.preferredGenres.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rp.preferredGenres[i],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            if (rp.preferredGenres.isNotEmpty) const SizedBox(height: 10),

            // Mini DNA bars
            Row(
              children: [
                _MiniBar(
                  label: l10n.readerProfileCharacterFocus,
                  value: rp.profileScore.characterFocus,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                _MiniBar(
                  label: l10n.readerProfilePlotFocus,
                  value: rp.profileScore.plotFocus,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                _MiniBar(
                  label: l10n.readerProfileAtmosphere,
                  value: rp.profileScore.atmosphereFocus,
                  color: AppColors.amber,
                ),
                const SizedBox(width: 6),
                _MiniBar(
                  label: l10n.readerProfilePace,
                  value: rp.profileScore.paceSlow,
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/reader_profile.dart';
import '../../../core/widgets/mascot_widget.dart';

class ReaderProfileCard extends StatelessWidget {
  final ReaderProfile? profile;
  final VoidCallback onTap;

  const ReaderProfileCard({
    super.key,
    this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return _buildEmptyState();
    }
    return _buildFilledState(profile!);
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const MascotWidget(size: 48, showGlow: false),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Okuyucu Arketipini Keşfet', // TODO: l10n
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kısa bir quiz ile kişiselleştirilmiş öneriler al', // TODO: l10n
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledState(ReaderProfile profile) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: archetype name + update button
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.archetypeName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Güncelle', // TODO: l10n
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Genre chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: profile.preferredGenres.map((genre) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        genre,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Mini progress indicators
            Row(
              children: [
                _buildMiniBar(
                  'Karakter', // TODO: l10n
                  profile.profileScore.characterFocus,
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildMiniBar(
                  'Olay Örgüsü', // TODO: l10n
                  profile.profileScore.plotFocus,
                  AppColors.success,
                ),
                const SizedBox(width: 8),
                _buildMiniBar(
                  'Atmosfer', // TODO: l10n
                  profile.profileScore.atmosphereFocus,
                  AppColors.amber,
                ),
                const SizedBox(width: 8),
                _buildMiniBar(
                  'Tempo', // TODO: l10n
                  profile.profileScore.paceSlow,
                  const Color(0xFF06B6D4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBar(String label, int value, Color color) {
    final clampedValue = value.clamp(0, 100);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedValue / 100,
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

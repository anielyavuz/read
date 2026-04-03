import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/game_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/challenge_template.dart';

class TemplateCard extends StatelessWidget {
  final ChallengeTemplate template;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _resolveTitle(l10n, template.titleKey);
    final description = _resolveDesc(l10n, template.descriptionKey);

    return SizedBox(
      width: 200,
      child: GameButton(
        onTap: onTap,
        color: template.color.withValues(alpha: 0.15),
        shadowColor: template.color.withValues(alpha: 0.3),
        shadowHeight: 4,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            template.color.withValues(alpha: 0.2),
            template.color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: template.color.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + duration badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  template.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: template.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.daysLabel(template.durationDays),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: template.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Description
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Target info
            _TargetChip(template: template, l10n: l10n),
          ],
        ),
      ),
    );
  }

  static String _resolveTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'templateWeekendSprint':
        return l10n.templateWeekendSprint;
      case 'templatePageTurner':
        return l10n.templatePageTurner;
      case 'templateGenreExplorer':
        return l10n.templateGenreExplorer;
      case 'templateSpeedReader':
        return l10n.templateSpeedReader;
      case 'templateBookClub':
        return l10n.templateBookClub;
      case 'templateFocusMarathon':
        return l10n.templateFocusMarathon;
      default:
        return key;
    }
  }

  static String _resolveDesc(AppLocalizations l10n, String key) {
    switch (key) {
      case 'templateWeekendSprintDesc':
        return l10n.templateWeekendSprintDesc;
      case 'templatePageTurnerDesc':
        return l10n.templatePageTurnerDesc;
      case 'templateGenreExplorerDesc':
        return l10n.templateGenreExplorerDesc;
      case 'templateSpeedReaderDesc':
        return l10n.templateSpeedReaderDesc;
      case 'templateBookClubDesc':
        return l10n.templateBookClubDesc;
      case 'templateFocusMarathonDesc':
        return l10n.templateFocusMarathonDesc;
      default:
        return key;
    }
  }
}

class _TargetChip extends StatelessWidget {
  final ChallengeTemplate template;
  final AppLocalizations l10n;

  const _TargetChip({required this.template, required this.l10n});

  @override
  Widget build(BuildContext context) {
    String label;
    if (template.targetPages != null) {
      label = '${template.targetPages} ${l10n.targetPages.toLowerCase()}';
    } else if (template.targetBooks != null) {
      label = '${template.targetBooks} ${l10n.targetBooks.toLowerCase()}';
    } else if (template.targetMinutes != null) {
      label = '${template.targetMinutes} min';
    } else {
      label = '';
    }

    return Row(
      children: [
        Icon(
          template.icon,
          size: 14,
          color: template.color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: template.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

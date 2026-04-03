import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class ReadingTimeScreen extends StatefulWidget {
  const ReadingTimeScreen({super.key});

  @override
  State<ReadingTimeScreen> createState() => _ReadingTimeScreenState();
}

class _ReadingTimeScreenState extends State<ReadingTimeScreen> {
  String? _selectedTime;
  TimeOfDay? _customTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeOptions = _buildTimeOptions(l10n);

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.whenDoYouRead,
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
                      l10n.readingTimeSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...timeOptions.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTimeCard(option),
                        )),
                    _buildCustomTimeCard(l10n),
                    const SizedBox(height: 20),
                    _buildMotivationCard(l10n),
                    const SizedBox(height: 16),
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
                  onPressed: _selectedTime != null ? _onStart : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.readyToStart),
                      const SizedBox(width: 8),
                      const Icon(Icons.rocket_launch, size: 20),
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
          _dot(false),
          const SizedBox(width: 12),
          _dot(true),
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

  List<_TimeOption> _buildTimeOptions(AppLocalizations l10n) {
    return [
      _TimeOption('morning', l10n.timeMorning, l10n.timeMorningDesc, Icons.wb_sunny, animatedEmoji: AnimatedEmojis.sunWithFace),
      _TimeOption('afternoon', l10n.timeAfternoon, l10n.timeAfternoonDesc, Icons.wb_cloudy),
      _TimeOption('evening', l10n.timeEvening, l10n.timeEveningDesc, Icons.wb_twilight, animatedEmoji: AnimatedEmojis.sunrise),
      _TimeOption('night', l10n.timeNight, l10n.timeNightDesc, Icons.nights_stay, animatedEmoji: AnimatedEmojis.moonFaceFirstQuarter),
    ];
  }

  Widget _buildTimeCard(_TimeOption option) {
    final isSelected = _selectedTime == option.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTime = option.id;
        _customTime = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: option.animatedEmoji != null
                  ? AnimatedEmoji(option.animatedEmoji!, size: 24)
                  : Icon(
                      option.icon,
                      size: 24,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimeCard(AppLocalizations l10n) {
    final isSelected = _selectedTime == 'custom';
    final timeText = _customTime != null
        ? _customTime!.format(context)
        : l10n.timeCustomDesc;

    return GestureDetector(
      onTap: () => _pickCustomTime(l10n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.schedule,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.timeCustom,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomTime(AppLocalizations l10n) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customTime ?? const TimeOfDay(hour: 20, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surfaceDark,
              dialBackgroundColor: AppColors.backgroundDark,
              hourMinuteColor: AppColors.backgroundDark,
              dayPeriodColor: AppColors.primary.withValues(alpha: 0.2),
              dialHandColor: AppColors.primary,
              entryModeIconColor: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customTime = picked;
        _selectedTime = 'custom';
      });
    }
  }

  Widget _buildMotivationCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: l10n.readingTimeMotivationPrefix),
                  TextSpan(
                    text: l10n.readingTimeMotivationHighlight,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: l10n.readingTimeMotivationSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _onStart() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Request notification permission and setup FCM
      await getIt<NotificationService>().requestPermissionAndSetup();

      // Save reading time and mark onboarding complete
      final customTimeStr = _customTime != null
          ? '${_customTime!.hour.toString().padLeft(2, '0')}:${_customTime!.minute.toString().padLeft(2, '0')}'
          : null;

      await getIt<UserProfileService>().saveReadingTimeAndFinish(
        readingTime: _selectedTime!,
        customReadingTime: customTimeStr,
      );
    } catch (_) {
      // Continue even if save fails
    }

    if (mounted) {
      context.push('/reader-profile-onboarding');
    }
  }
}

class _TimeOption {
  final String id;
  final String label;
  final String desc;
  final IconData icon;
  final AnimatedEmojiData? animatedEmoji;

  const _TimeOption(this.id, this.label, this.desc, this.icon, {this.animatedEmoji});
}

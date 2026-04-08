import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/notification_settings_cubit.dart';
import '../cubit/notification_settings_state.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => getIt<NotificationSettingsCubit>()
        ..setLocalizedStrings(
          title: l10n.readingReminderNotifTitle,
          body: l10n.readingReminderNotifBody,
        )
        ..loadPreferences(),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          l10n.notificationSettings,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) {
          if (state.status == NotificationSettingsStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == NotificationSettingsStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? l10n.somethingWentWrong,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final prefs = state.preferences;
          final cubit = context.read<NotificationSettingsCubit>();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master toggle
                      _buildSectionCard(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n.enableNotifications,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: !prefs.enabled
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      l10n.notificationsDisabledDesc,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : null,
                            value: prefs.enabled,
                            onChanged: (_) => cubit.toggleEnabled(),
                            activeColor: AppColors.primary,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ],
                      ),

                      if (prefs.enabled) ...[
                        const SizedBox(height: 20),

                        // Reading Reminder section
                        _buildSectionHeader(l10n.readingReminder),
                        const SizedBox(height: 8),
                        _buildSectionCard(
                          children: [
                            // Weekday time
                            _buildTimeTile(
                              context: context,
                              title: l10n.weekdayReminder,
                              currentTime: prefs.weekdayTime,
                              onTimePicked: (time) =>
                                  cubit.updateWeekdayTime(time),
                            ),
                            const Divider(
                              color: AppColors.dividerDark,
                              height: 1,
                            ),
                            // Weekend time
                            _buildTimeTile(
                              context: context,
                              title: l10n.weekendReminder,
                              currentTime: prefs.weekendTime,
                              onTimePicked: (time) =>
                                  cubit.updateWeekendTime(time),
                            ),
                            const Divider(
                              color: AppColors.dividerDark,
                              height: 1,
                            ),
                            // Reading duration goal
                            _buildDurationSelector(
                              context: context,
                              l10n: l10n,
                              currentDuration: prefs.readingDurationGoal,
                              onChanged: (val) => cubit.setReadingDuration(val),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            top: 8,
                            bottom: 4,
                          ),
                          child: Text(
                            l10n.reminderInfo,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Smart Alerts section
                        _buildSectionHeader(l10n.smartAlerts),
                        const SizedBox(height: 8),
                        _buildSectionCard(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.streakRiskAlert,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  l10n.streakRiskAlertDesc,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              value: prefs.streakReminder,
                              onChanged: (_) => cubit.toggleStreakReminder(),
                              activeColor: AppColors.primary,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            const Divider(
                              color: AppColors.dividerDark,
                              height: 1,
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.challengeNotificationsToggle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  l10n.challengeNotificationsDesc,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              value: prefs.challengeNotifications,
                              onChanged: (_) =>
                                  cubit.toggleChallengeNotifications(),
                              activeColor: AppColors.primary,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Quiet Hours
                        _buildSectionCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bedtime_rounded,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.quietHours,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.quietHoursDesc,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
              // Save button
              if (state.hasUnsavedChanges)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isSaving
                          ? null
                          : () => cubit.saveChanges(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.saveNotificationSettings,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTimeTile({
    required BuildContext context,
    required String title,
    required String currentTime,
    required ValueChanged<String> onTimePicked,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => _showTimePicker(context, currentTime, onTimePicked),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            currentTime,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onTimePicked,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 21,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.backgroundDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onTimePicked('$h:$m');
    }
  }

  Widget _buildDurationSelector({
    required BuildContext context,
    required AppLocalizations l10n,
    required int currentDuration,
    required ValueChanged<int> onChanged,
  }) {
    const durations = [15, 30, 45, 60];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.readingGoalDuration,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: durations.contains(currentDuration) ? currentDuration : 30,
            dropdownColor: AppColors.surfaceDark,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primary,
            ),
            items: durations.map((d) {
              return DropdownMenuItem<int>(
                value: d,
                child: Text(l10n.minutesDuration(d)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/challenge.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/create_challenge_cubit.dart';
import '../cubit/create_challenge_state.dart';

class CreateChallengeScreen extends StatelessWidget {
  const CreateChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateChallengeCubit>(),
      child: const _CreateChallengeContent(),
    );
  }
}

class _CreateChallengeContent extends StatefulWidget {
  const _CreateChallengeContent();

  @override
  State<_CreateChallengeContent> createState() =>
      _CreateChallengeContentState();
}

class _CreateChallengeContentState extends State<_CreateChallengeContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  /// true = daily pages, false = daily minutes
  bool _isDailyPages = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublic = true;

  // Friend picker state
  List<FriendWithProfile> _friends = [];
  final Set<String> _selectedFriendIds = {};
  bool _friendsLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          l10n.createChallenge,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocListener<CreateChallengeCubit, CreateChallengeState>(
        listener: (context, state) {
          if (state.status == CreateChallengeStatus.created) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.challengeCreated),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state.status == CreateChallengeStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              _buildLabel(l10n.challengeTitle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(l10n.challengeTitleHint),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.errorFieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Challenge type toggle
              _buildLabel(l10n.challengeGoalType),
              const SizedBox(height: 8),
              _buildTypeToggle(l10n),
              const SizedBox(height: 24),

              // Target value
              _buildLabel(
                _isDailyPages
                    ? l10n.challengeDailyPagesTarget
                    : l10n.challengeDailyMinutesTarget,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  _isDailyPages
                      ? l10n.challengeDailyPagesHint
                      : l10n.challengeDailyMinutesHint,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.errorFieldRequired;
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return l10n.errorFieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Start date
              _buildLabel(l10n.startDate),
              const SizedBox(height: 8),
              _buildDatePicker(
                context,
                dateFormat.format(_startDate),
                () => _selectDate(context, isStart: true),
              ),
              const SizedBox(height: 24),

              // End date
              _buildLabel(l10n.endDate),
              const SizedBox(height: 8),
              _buildDatePicker(
                context,
                dateFormat.format(_endDate),
                () => _selectDate(context, isStart: false),
              ),
              const SizedBox(height: 24),

              // Visibility toggle
              _buildLabel(l10n.challengeVisibility),
              const SizedBox(height: 8),
              _buildVisibilityToggle(l10n),

              // Friend picker (only when private)
              if (!_isPublic) ...[
                const SizedBox(height: 24),
                _buildLabel(l10n.selectFriendsToInvite),
                const SizedBox(height: 8),
                _buildFriendPicker(l10n),
              ],

              const SizedBox(height: 32),

              // Create button
              BlocBuilder<CreateChallengeCubit, CreateChallengeState>(
                builder: (context, state) {
                  final isCreating =
                      state.status == CreateChallengeStatus.creating;

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isCreating ? null : _onCreatePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.createChallenge,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isDailyPages = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isDailyPages
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDailyPages
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: _isDailyPages
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.challengeDailyPages,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isDailyPages
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isDailyPages = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_isDailyPages
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isDailyPages
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timer_rounded,
                    color: !_isDailyPages
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.challengeDailyMinutes,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !_isDailyPages
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isPublic = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isPublic
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPublic
                      ? AppColors.success
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.public_rounded,
                    color: _isPublic
                        ? AppColors.success
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.publicChallenge,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isPublic
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _isPublic = false);
              if (_friends.isEmpty) _loadFriends();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_isPublic
                    ? AppColors.amber.withValues(alpha: 0.15)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isPublic
                      ? AppColors.amber
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: !_isPublic
                        ? AppColors.amber
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.privateChallenge,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !_isPublic
                          ? AppColors.amber
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendPicker(AppLocalizations l10n) {
    if (_friendsLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            l10n.noFriendsYet,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _friends.map((friend) {
          final isSelected = _selectedFriendIds.contains(friend.profile.uid);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedFriendIds.remove(friend.profile.uid);
                } else {
                  _selectedFriendIds.add(friend.profile.uid);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: friend.profile.avatarUrl != null
                        ? NetworkImage(friend.profile.avatarUrl!)
                        : null,
                    child: friend.profile.avatarUrl == null
                        ? Text(
                            friend.profile.displayName.isNotEmpty
                                ? friend.profile.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      friend.profile.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadFriends() async {
    setState(() => _friendsLoading = true);
    try {
      final friendshipService = getIt<FriendshipService>();
      final friends = await friendshipService.getAcceptedFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _friendsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _friendsLoading = false);
      }
    }
  }

  void _onCreatePressed() {
    if (!_formKey.currentState!.validate()) return;

    final targetValue = int.tryParse(_targetController.text.trim()) ?? 0;

    context.read<CreateChallengeCubit>().createChallenge(
          title: _titleController.text.trim(),
          type: _isDailyPages ? ChallengeType.pages : ChallengeType.sprint,
          targetPages: _isDailyPages ? targetValue : null,
          targetMinutes: !_isDailyPages ? targetValue : null,
          startDate: _startDate,
          endDate: _endDate,
          isPublic: _isPublic,
          invitedFriendIds: _selectedFriendIds.toList(),
        );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String displayText,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayText,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceDark,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

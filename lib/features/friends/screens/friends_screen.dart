import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/friendship.dart';
import '../../../core/services/friendship_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/friends_cubit.dart';
import '../cubit/friends_state.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FriendsCubit>()..loadFriends(),
      child: const _FriendsScreenContent(),
    );
  }
}

class _FriendsScreenContent extends StatefulWidget {
  const _FriendsScreenContent();

  @override
  State<_FriendsScreenContent> createState() => _FriendsScreenContentState();
}

class _FriendsScreenContentState extends State<_FriendsScreenContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _shortId(String uid) =>
      uid.length >= 4 ? uid.substring(uid.length - 4) : uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friends),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: BlocBuilder<FriendsCubit, FriendsState>(
        builder: (context, state) {
          final hasText = state.searchQuery.trim().isNotEmpty;
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) =>
                      context.read<FriendsCubit>().updateSearchQuery(q),
                  onSubmitted: (_) =>
                      context.read<FriendsCubit>().performSearch(),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.searchFriends,
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: hasText
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send_rounded,
                                    color: AppColors.primary),
                                onPressed: () => context
                                    .read<FriendsCubit>()
                                    .performSearch(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<FriendsCubit>().clearSearch();
                                },
                              ),
                            ],
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: state.hasSearched || state.isSearching
                    ? _buildSearchResults(context, state, l10n)
                    : _buildFriendsList(context, state, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAction(
      BuildContext context, AppLocalizations l10n, String uid, FriendshipStatus? status) {
    if (status == FriendshipStatus.accepted) {
      return Text(
        l10n.alreadyFriends,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }
    if (status == FriendshipStatus.pending) {
      return Text(
        l10n.pendingRequest,
        style: const TextStyle(fontSize: 13, color: AppColors.amber),
      );
    }
    return TextButton(
      onPressed: () => context.read<FriendsCubit>().sendRequest(uid),
      child: Text(l10n.addFriend),
    );
  }

  Widget _buildSearchResults(
      BuildContext context, FriendsState state, AppLocalizations l10n) {
    if (state.isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          l10n.noUsersFound,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = state.searchResults[index];
        final user = result.profile;
        final shortId = _shortId(user.uid);
        final status = result.friendship?.status;

        return Card(
          color: AppColors.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            title: Text(
              '${user.displayName}  #$shortId',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            subtitle: Text(
              l10n.xpTotal(user.xpTotal),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: _buildSearchAction(context, l10n, user.uid, status),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(
      BuildContext context, FriendsState state, AppLocalizations l10n) {
    if (state.status == FriendsStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<FriendsCubit>().loadFriends(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // My profile card
          if (user != null) ...[
            Card(
              color: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          (user.displayName ?? '').isNotEmpty
                              ? user.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                title: Text(
                  '${user.displayName ?? ''} (#${_shortId(user.uid)})',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  l10n.shareProfile,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                trailing: IconButton(
                  onPressed: () {
                    final name = user.displayName ?? '';
                    final shortId = _shortId(user.uid);
                    final text = l10n.shareProfileText(name, shortId);
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                  icon: const Icon(Icons.share_rounded),
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pending requests
          if (state.pendingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  AnimatedEmoji(AnimatedEmojis.handshake, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.pendingRequests(state.pendingRequests.length),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            ...state.pendingRequests.map((fwp) {
              final p = fwp.profile;
              final shortId = _shortId(p.uid);
              return Card(
                color: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: p.avatarUrl != null
                        ? NetworkImage(p.avatarUrl!)
                        : null,
                    child: p.avatarUrl == null
                        ? Text(
                            p.displayName.isNotEmpty
                                ? p.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                  title: Text(
                    '${p.displayName}  #$shortId',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.wantsToBeYourFriend,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => context
                            .read<FriendsCubit>()
                            .acceptRequest(fwp.friendship.id),
                        icon: const Icon(Icons.check_circle_rounded),
                        color: const Color(0xFF4ADE80),
                        tooltip: l10n.accept,
                      ),
                      IconButton(
                        onPressed: () => context
                            .read<FriendsCubit>()
                            .declineRequest(fwp.friendship.id),
                        icon: const Icon(Icons.cancel_rounded),
                        color: AppColors.textMuted,
                        tooltip: l10n.decline,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Friends
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              l10n.friendsCount(state.friends.length),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
          if (state.friends.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    AnimatedEmoji(AnimatedEmojis.hugFace, size: 48),
                    const SizedBox(height: 12),
                    Text(l10n.noFriendsYet,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(l10n.searchToAddFriends,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...state.friends.map((fwp) => _FriendCard(
                  fwp: fwp,
                  shortId: _shortId(fwp.profile.uid),
                )),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendWithProfile fwp;
  final String shortId;

  const _FriendCard({required this.fwp, required this.shortId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = fwp.profile;
    final books = fwp.currentlyReading;

    return Card(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: avatar + name + stats + remove button
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                  child: p.avatarUrl == null
                      ? Text(
                          p.displayName.isNotEmpty
                              ? p.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.displayName}  #$shortId',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              size: 13, color: AppColors.amber),
                          const SizedBox(width: 3),
                          Text(l10n.dayStreak(p.streakDays),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(width: 10),
                          Text(l10n.xpTotal(p.xpTotal),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmRemove(context, l10n, p.displayName),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.person_remove_rounded,
                        size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),

            // Currently reading books
            if (books.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 13,
                            color: AppColors.primary.withValues(alpha: 0.7)),
                        const SizedBox(width: 5),
                        Text(
                          l10n.currentlyReading,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...books.map((book) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 4, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  book.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (book.totalPages > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${((book.currentPage / book.totalPages) * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Text(
                  l10n.notReadingAnything,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, AppLocalizations l10n, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.removeFriend,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.removeFriendConfirm(name),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(l10n.removeFriend, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<FriendsCubit>().removeFriend(fwp.friendship.id);
    }
  }
}

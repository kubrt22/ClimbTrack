import 'dart:async';

import 'package:climb_track/UI/friends/friends_list.dart';
import 'package:climb_track/UI/friends/leaderboard.dart';
import 'package:climb_track/UI/friends/profile.dart';
import 'package:climb_track/models/user_profile_model.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/friends_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  static AppBar buildAppBar(WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return AppBar(
      title: const Text('Přátelé'),
      actions: [
        IconButton(
          onPressed: user == null
              ? null
              : () {
                  Navigator.push(
                    ref.context,
                    MaterialPageRoute(
                      builder: (context) => FriendProfilePage(userId: user.uid),
                    ),
                  );
                },
          tooltip: 'Můj profil',
          icon: const Icon(Icons.account_circle_rounded),
        ),
      ],
    );
  }

  static FloatingActionButton? buildFAB(WidgetRef ref) {
    final tabIndex = ref.watch(friendsTabIndexProvider);
    if (tabIndex != 1) return null;

    return FloatingActionButton(
      onPressed: () => _openAddFriendDialog(ref),
      tooltip: 'Přidat přítele',
      child: const Icon(Icons.person_add_alt_1_rounded),
    );
  }

  static Future<void> _openAddFriendDialog(WidgetRef ref) async {
    await showDialog<void>(
      context: ref.context,
      builder: (context) => const _UserSearchDialog(),
    );
  }

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  void _syncTabIndexPostFrame([int? index]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(friendsTabIndexProvider.notifier)
          .setIndex(index ?? _tabController.index);
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _syncTabIndexPostFrame(_tabController.index);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _syncTabIndexPostFrame(_tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapCurrentUser());
    });
  }

  Future<void> _bootstrapCurrentUser() async {
    try {
      await ref.read(friendsControllerProvider).ensureCurrentUserDocument();
      if (!mounted) return;

      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(currentUserStatsProvider);
      ref.invalidate(incomingFriendRequestsProvider);
      ref.invalidate(outgoingFriendRequestsProvider);
      ref.invalidate(friendsMembersProvider);
      ref.invalidate(friendsLeaderboardProvider);
    } catch (_) {
      if (!mounted) return;
      showError(context, 'Nepodařilo se načíst data přátel.');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          controller: _tabController,
          tabs: const [
            Tab(text: 'Leaderboard'),
            Tab(text: 'Přátelé'),
          ],
        ),
        Expanded(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBarView(
              controller: _tabController,
              children: const [LeaderboardTab(), FriendsListTab()],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserSearchDialog extends ConsumerStatefulWidget {
  const _UserSearchDialog();

  @override
  ConsumerState<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends ConsumerState<_UserSearchDialog> {
  late final TextEditingController _searchController;

  bool _isSearching = false;
  String? _sendingUid;
  String? _statusMessage;
  List<UserProfileModel> _results = const [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _statusMessage = 'Zadejte jméno uživatele';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _statusMessage = null;
    });

    try {
      final users = await ref
          .read(friendsControllerProvider)
          .searchUserProfilesByUsername(query);

      if (!mounted) return;

      setState(() {
        _results = users;
        _statusMessage = users.isEmpty
            ? 'Žádný uživatel nenalezen'
            : 'Vyberte uživatele';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _statusMessage = 'Vyhledávání se nepodařilo';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(UserProfileModel target) async {
    if (_sendingUid != null) return;

    setState(() {
      _sendingUid = target.uid;
    });

    try {
      await ref
          .read(friendsControllerProvider)
          .sendFriendRequestToUser(
            targetUid: target.uid,
            targetUsername: target.username,
          );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Žádost o přátelství pro ${target.username} byla odeslána.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
      showError(context, message);
    } finally {
      if (!mounted) return;
      setState(() {
        _sendingUid = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Najít uživatele'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Jméno uživatele',
                hintText: 'Např. Kuba',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSearching ? null : _searchUsers,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Hledat'),
              ),
            ),
            const SizedBox(height: 12),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else if (_statusMessage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_statusMessage!),
                ),
              ),
            if (_results.isNotEmpty)
              SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final isSending = _sendingUid == user.uid;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_rounded),
                      title: Text(user.username),
                      trailing: FilledButton(
                        onPressed: isSending ? null : () => _sendRequest(user),
                        child: Text(isSending ? 'Odesílám...' : 'Přidat'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zavřít'),
        ),
      ],
    );
  }
}

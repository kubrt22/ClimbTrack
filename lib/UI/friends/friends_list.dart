import 'package:climb_track/UI/friends/profile.dart';
import 'package:climb_track/UI/widgets/friend_list_item.dart';
import 'package:climb_track/models/friend_request_model.dart';
import 'package:climb_track/provider/friends_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendsListTab extends ConsumerWidget {
  const FriendsListTab({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildRequestCard({
    required BuildContext context,
    required FriendRequestModel request,
    required VoidCallback? onAccept,
    required VoidCallback? onReject,
    required bool showActions,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF49454F), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.mail_outline_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                showActions ? request.fromUsername : request.toUsername,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (showActions) ...[
              IconButton(
                onPressed: onReject,
                tooltip: 'Odmítnout',
                icon: const Icon(Icons.close_rounded),
              ),
              IconButton(
                onPressed: onAccept,
                tooltip: 'Přijmout',
                icon: const Icon(Icons.check_rounded),
              ),
            ] else
              Text('Čeká', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsMembersProvider);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final outgoingAsync = ref.watch(outgoingFriendRequestsProvider);

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (friends) {
        final incomingRequests = incomingAsync.maybeWhen(
          data: (requests) => requests,
          orElse: () => const <FriendRequestModel>[],
        );

        final outgoingRequests = outgoingAsync.maybeWhen(
          data: (requests) => requests,
          orElse: () => const <FriendRequestModel>[],
        );

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            _buildSectionHeader(context, 'Příchozí žádosti'),
            if (incomingRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text('Žádné čekající žádosti'),
              )
            else
              ...incomingRequests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildRequestCard(
                    context: context,
                    request: request,
                    showActions: true,
                    onAccept: () async {
                      try {
                        await ref
                            .read(friendsControllerProvider)
                            .acceptFriendRequest(request.id);
                      } catch (e) {
                        if (!context.mounted) return;
                        showError(context, e.toString());
                      }
                    },
                    onReject: () async {
                      try {
                        await ref
                            .read(friendsControllerProvider)
                            .rejectFriendRequest(request.id);
                      } catch (e) {
                        if (!context.mounted) return;
                        showError(context, e.toString());
                      }
                    },
                  ),
                ),
              ),

            _buildSectionHeader(context, 'Odeslané žádosti'),
            if (outgoingRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text('Žádné odeslané žádosti'),
              )
            else
              ...outgoingRequests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildRequestCard(
                    context: context,
                    request: request,
                    showActions: false,
                    onAccept: null,
                    onReject: null,
                  ),
                ),
              ),

            _buildSectionHeader(context, 'Přátelé'),
            if (friends.isEmpty)
              const Text('Zatím žádní přátelé')
            else
              ...friends.map(
                (friend) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FriendListTile(
                    title: friend.profile.username,
                    subtitle:
                        '${friend.stats.totalAscents} výstupů • ${friend.stats.sessionsCount} sessions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FriendProfilePage(userId: friend.profile.uid),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

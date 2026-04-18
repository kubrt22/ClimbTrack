import 'package:climb_track/UI/friends/profile.dart';
import 'package:climb_track/UI/widgets/leaderboard_list_item.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/friends_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key});

  String _climbTypeLabel(ClimbType climbType) {
    switch (climbType) {
      case ClimbType.Boulder:
        return 'Boulder';
      case ClimbType.Toprope:
        return 'Toprope';
      case ClimbType.Lead:
        return 'Lead';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedClimbType = ref.watch(leaderboardClimbTypeProvider);
    final leaderboardAsync = ref.watch(friendsLeaderboardProvider);
    final currentUid = ref.watch(authStateProvider).value?.uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<ClimbType>(
            showSelectedIcon: false,
            segments: [
              for (final climbType in ClimbType.values)
                ButtonSegment(
                  value: climbType,
                  label: Text(_climbTypeLabel(climbType)),
                ),
            ],
            selected: {selectedClimbType},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              ref
                  .read(leaderboardClimbTypeProvider.notifier)
                  .setType(selection.first);
            },
          ),
        ),
        Expanded(
          child: leaderboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (members) {
              if (members.isEmpty) {
                return const Center(
                  child: Text('Zatím žádní přátelé pro leaderboard'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8.0),
                itemCount: members.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final subtitle =
                      '${member.stats.totalAscents} výstupů • ${member.stats.sessionsCount} sessions';

                  return LeaderboardListTile(
                    rank: index + 1,
                    username: member.profile.username,
                    subtitle: subtitle,
                    points: member.stats.pointsForClimbType(selectedClimbType),
                    isCurrentUser: member.profile.uid == currentUid,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FriendProfilePage(userId: member.profile.uid),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:climb_track/provider/friends_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendProfilePage extends ConsumerWidget {
  final String userId;

  const FriendProfilePage({super.key, required this.userId});

  Widget _statCard(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF49454F), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canViewAsync = ref.watch(canViewUserProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: canViewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (canView) {
          if (!canView) {
            return const Center(
              child: Text('Tento profil je dostupný jen pro přátele.'),
            );
          }

          final profileAsync = ref.watch(userProfileByUidProvider(userId));
          final statsAsync = ref.watch(userStatsByUidProvider(userId));

          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('Profil nenalezen.'));
              }

              return statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (stats) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.username,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            _statCard(
                              context,
                              'Total ascents',
                              '${stats.totalAscents}',
                            ),
                            const SizedBox(width: 8),
                            _statCard(
                              context,
                              'Sessions',
                              '${stats.sessionsCount}',
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Hardest climb per type',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF49454F),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              for (final difficultyType
                                  in DifficultyType.values)
                                ListTile(
                                  title: Text(difficultyType.name),
                                  trailing: Text(
                                    stats.hardestForDifficultyType(
                                      difficultyType,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

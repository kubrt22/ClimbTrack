import 'package:flutter/material.dart';

import 'package:climb_track/UI/widgets/session_list_item.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/riverpod.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/UI/session/session_add.dart';
import 'package:climb_track/UI/routes/route_add.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();

  static AppBar buildAppBar(WidgetRef ref) {
    final auth = ref.read(authServiceProvider);

    return AppBar(
      title: const Text('Přehled'),
      actions: [
        IconButton(
          onPressed: () async => await auth.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  static FloatingActionButton buildFAB(WidgetRef ref) {
    final tabIndex = ref.watch(overviewTabIndexProvider);
    return FloatingActionButton(
      onPressed: () {
        final user = ref.read(authStateProvider).value;
        if (user == null) return;
        final firestore = ref.read(firestoreServiceProvider);
        if (tabIndex == 0) {
          Navigator.push(
            ref.context,
            MaterialPageRoute(builder: (context) => SessionAddPage()),
          );
        } else {
          Navigator.push(
            ref.context,
            MaterialPageRoute(builder: (context) => RouteAddPage()),
          );
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class _OverviewPageState extends ConsumerState<OverviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(overviewTabIndexProvider.notifier)
            .setIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);
    final routesAsync = ref.watch(routesStreamProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Sessions"),
            Tab(text: "Cesty"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (sessions) => sessions.isEmpty
                    ? const Center(child: Text('No sessions yet'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8.0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8.0),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final s = sessions[index];
                          final sessionRoutes = ref.watch(
                            sessionRoutesProvider(s.routeIds),
                          );
                          return sessionRoutes.when(
                            loading: () => const SizedBox.shrink(),
                            error: (err, stack) => const SizedBox.shrink(),
                            data: (routes) {
                              final sorted = List.from(routes);
                              sorted.sort(
                                (a, b) => b.difficulty.index.compareTo(
                                  a.difficulty.index,
                                ),
                              );

                              return SessionListTile(
                                id: s.id,
                                title: s.title,
                                location: s.location,
                                ascentsCount: sorted.length,
                                difficulty: sorted.isNotEmpty
                                    ? sorted.first.difficulty
                                    : Difficulty(DifficultyType.V_Scale, "V0"),
                                color: sorted.isNotEmpty
                                    ? sorted.first.routeColor
                                    : Colors.grey,
                              );
                            },
                          );
                        },
                      ),
              ),
              routesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (routes) => routes.isEmpty
                    ? const Center(child: Text('No routes yet'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8.0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8.0),
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final r = routes[index];
                          return RouteListTile(
                            id: r.id,
                            title: r.title,
                            location: r.location,
                            date: r.date,
                            climbType: r.climbType,
                            climbStyle: r.climbStyle,
                            difficulty: r.difficulty,
                            color: r.routeColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

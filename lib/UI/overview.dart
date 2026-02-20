import 'package:flutter/material.dart';

import 'package:climb_track/UI/widgets/session_list_item.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/riverpod.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/models/route_model.dart';
import 'package:climb_track/models/session_model.dart';

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
          final session = SessionModel(
            id: '',
            title: 'Nová session',
            location: 'Neznámé místo',
            durationMinutes: 90,
            routeIds: ["6WhEwGgBmPUGP1gci0wI"],
            createdAt: DateTime.now(),
          );
          firestore.addSession(user.uid, session);
        } else {
          final route = RouteModel(
            id: '',
            title: 'Nová cesta',
            location: 'Neznámé místo',
            date: DateTime.now(),
            climbType: ClimbType.Boulder,
            climbStyle: ClimbStyle.Flash,
            difficulty: Difficulty(DifficultyType.V_Scale, "V9"),
            routeColor: 0xFF2196F3,
            createdAt: DateTime.now(),
          );
          firestore.addRoute(user.uid, route);
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
                            data: (routes) => SessionListTile(
                              title: s.title,
                              location: s.location,
                              ascentsCount: s.routeIds.length,
                              difficulty: routes.isNotEmpty
                                  ? routes[0].difficulty
                                  : Difficulty(DifficultyType.V_Scale, "V0"),
                              color: Color(0xFF2196F3),
                            ),
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
                            title: r.title,
                            location: r.location,
                            date: r.date,
                            climbType: r.climbType,
                            climbStyle: r.climbStyle,
                            difficulty: r.difficulty,
                            color: Color(r.routeColor),
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

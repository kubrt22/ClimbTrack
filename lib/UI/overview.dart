import 'package:flutter/material.dart';

import 'package:climb_track/UI/widgets/session_list_item.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:climb_track/models/route_model.dart';
import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/models/user_settings_model.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/riverpod.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/provider/settings_provider.dart';
import 'package:climb_track/UI/session/session_add.dart';
import 'package:climb_track/UI/routes/route_add.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();

  static FloatingActionButton buildFAB(WidgetRef ref) {
    final tabIndex = ref.watch(overviewTabIndexProvider);
    return FloatingActionButton(
      onPressed: () {
        final user = ref.read(authStateProvider).value;
        if (user == null) return;
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

  bool _sessionMatchesQuery(SessionModel session, String query) {
    if (query.isEmpty) return true;

    final dateText =
        '${session.date.day}.${session.date.month}.${session.date.year}';
    return session.title.toLowerCase().contains(query) ||
        session.location.toLowerCase().contains(query) ||
        session.notes.toLowerCase().contains(query) ||
        dateText.contains(query);
  }

  bool _routeMatchesQuery(RouteModel route, String query) {
    if (query.isEmpty) return true;

    final dateText = '${route.date.day}.${route.date.month}.${route.date.year}';
    final climbStyle = route.climbStyle?.name.toLowerCase() ?? '';
    return route.title.toLowerCase().contains(query) ||
        route.location.toLowerCase().contains(query) ||
        route.notes.toLowerCase().contains(query) ||
        route.climbType.name.toLowerCase().contains(query) ||
        climbStyle.contains(query) ||
        route.difficulty.value.toLowerCase().contains(query) ||
        route.difficulty.typeName.toLowerCase().contains(query) ||
        dateText.contains(query);
  }

  void _sortSessions(List<SessionModel> sessions, OverviewSortSetting sort) {
    switch (sort) {
      case OverviewSortSetting.newestFirst:
        sessions.sort((a, b) => b.date.compareTo(a.date));
      case OverviewSortSetting.oldestFirst:
        sessions.sort((a, b) => a.date.compareTo(b.date));
      case OverviewSortSetting.titleAZ:
        sessions.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case OverviewSortSetting.locationAZ:
        sessions.sort(
          (a, b) =>
              a.location.toLowerCase().compareTo(b.location.toLowerCase()),
        );
    }
  }

  void _sortRoutes(List<RouteModel> routes, OverviewSortSetting sort) {
    switch (sort) {
      case OverviewSortSetting.newestFirst:
        routes.sort((a, b) => b.date.compareTo(a.date));
      case OverviewSortSetting.oldestFirst:
        routes.sort((a, b) => a.date.compareTo(b.date));
      case OverviewSortSetting.titleAZ:
        routes.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case OverviewSortSetting.locationAZ:
        routes.sort(
          (a, b) =>
              a.location.toLowerCase().compareTo(b.location.toLowerCase()),
        );
    }
  }

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
    final settings = ref
        .watch(userSettingsProvider)
        .maybeWhen(data: (settings) => settings, orElse: UserSettings.defaults);
    final searchQuery = ref
        .watch(overviewSearchQueryProvider)
        .trim()
        .toLowerCase();

    return Column(
      children: [
        TabBar(
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          controller: _tabController,
          tabs: const [
            Tab(text: "Sessions"),
            Tab(text: "Cesty"),
          ],
        ),
        Expanded(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: TabBarView(
              controller: _tabController,
              children: [
                sessionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (sessions) {
                    final sortedSessions = List<SessionModel>.from(sessions);
                    _sortSessions(sortedSessions, settings.sessionsSort);
                    final filteredSessions = sortedSessions
                        .where(
                          (session) =>
                              _sessionMatchesQuery(session, searchQuery),
                        )
                        .toList();

                    return filteredSessions.isEmpty
                        ? Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No sessions yet'
                                  : 'No matching sessions',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8.0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8.0),
                            itemCount: filteredSessions.length,
                            itemBuilder: (context, index) {
                              final s = filteredSessions[index];
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
                                        : Difficulty(
                                            DifficultyType.V_Scale,
                                            "V0",
                                          ),
                                    color: sorted.isNotEmpty
                                        ? sorted.first.routeColor
                                        : Colors.grey,
                                  );
                                },
                              );
                            },
                          );
                  },
                ),
                routesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (routes) {
                    final sortedRoutes = List<RouteModel>.from(routes);
                    _sortRoutes(sortedRoutes, settings.routesSort);
                    final filteredRoutes = sortedRoutes
                        .where(
                          (route) => _routeMatchesQuery(route, searchQuery),
                        )
                        .toList();

                    return filteredRoutes.isEmpty
                        ? Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No routes yet'
                                  : 'No matching routes',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8.0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8.0),
                            itemCount: filteredRoutes.length,
                            itemBuilder: (context, index) {
                              final r = filteredRoutes[index];
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
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

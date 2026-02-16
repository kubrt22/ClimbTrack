import 'package:flutter/material.dart';

import 'package:climb_track/UI/widgets/session_list_item.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';

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
}

class _OverviewPageState extends ConsumerState<OverviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              ListView.separated(
                padding: const EdgeInsets.all(8.0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8.0),
                itemCount: 20,
                itemBuilder: (context, index) => SessionListTile(
                  title: 'Session ${index + 1}',
                  location: 'Location ${index + 1}',
                  ascentsCount: index + 1,
                  difficulty: Difficulty(
                    DifficultyType.V_Scale,
                    "V${index + 1}",
                  ),
                  color:
                      Colors.red[[
                        100,
                        200,
                        300,
                        400,
                        500,
                        600,
                        700,
                        800,
                        900,
                      ][index % 9]]!,
                ),
              ),
              ListView.separated(
                itemBuilder: (context, index) => RouteListTile(
                  title: 'Cesta ${index + 1}',
                  location: 'Location ${index + 1}',
                  date: DateTime.now(),
                  climbType: ClimbType.Boulder,
                  difficulty: Difficulty(
                    DifficultyType.V_Scale,
                    "V${index + 1}",
                  ),
                  climbStyle: ClimbStyle.Flash,
                  color:
                      Colors.blue[[
                        100,
                        200,
                        300,
                        400,
                        500,
                        600,
                        700,
                        800,
                        900,
                      ][index % 9]]!,
                ),
                padding: const EdgeInsets.all(8.0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8.0),
                itemCount: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

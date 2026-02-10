import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/UI/widgets/session_list_iten.dart';
import 'package:climb_track/services/global_things.dart';

class Overview extends ConsumerStatefulWidget {
  const Overview({super.key});

  @override
  ConsumerState<Overview> createState() => _OverviewState();
}

class _OverviewState extends ConsumerState<Overview>
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
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Přehled'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Sessions"),
            Tab(text: "Cesty"),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(8.0),
              separatorBuilder: (context, index) => const SizedBox(height: 8.0),
              itemCount: 20,
              itemBuilder: (context, index) => SessionListTile(
                title: 'Session ${index + 1}',
                location: 'Location ${index + 1}',
                ascentsCount: index + 1,
                difficulty: Difficulty(DifficultyType.V_Scale, "V${index + 1}"),
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
            ListView(
              children: List.generate(
                20,
                (index) => ListTile(
                  title: Text('Cesta ${index + 1}'),
                  subtitle: Text('Details about cesta ${index + 1}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

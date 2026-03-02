import 'package:flutter/material.dart';

import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/UI/routes/route_add.dart';

class RouteSelectPage extends ConsumerStatefulWidget {
  final Set<String> initialSelected;

  const RouteSelectPage({super.key, required this.initialSelected});

  @override
  ConsumerState<RouteSelectPage> createState() => _RouteSelectPageState();
}

class _RouteSelectPageState extends ConsumerState<RouteSelectPage> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelected;
  }

  void _toggleSelection(String routeId) {
    setState(() {
      if (_selectedIds.contains(routeId)) {
        _selectedIds.remove(routeId);
      } else {
        _selectedIds.add(routeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Vybrat cesty (${_selectedIds.length})'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context, _selectedIds.toList()),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            ref.context,
            MaterialPageRoute(builder: (context) => RouteAddPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: routesAsync.when(
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
                  final isSelected = _selectedIds.contains(r.id);
                  return GestureDetector(
                    onTap: () => _toggleSelection(r.id),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IgnorePointer(
                          child: RouteListTile(
                            id: r.id,
                            title: r.title,
                            location: r.location,
                            date: r.date,
                            climbType: r.climbType,
                            climbStyle: r.climbStyle,
                            difficulty: r.difficulty,
                            color: r.routeColor,
                          ),
                        ),
                        Positioned.fill(
                          top: -2.5,
                          left: -2.5,
                          right: -2.5,
                          bottom: -2.5,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.5),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

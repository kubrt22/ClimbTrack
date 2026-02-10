import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/services/global_things.dart';

class SessionListTile extends ConsumerStatefulWidget {
  final String title;
  final String location;
  final int ascentsCount;
  final Difficulty difficulty;
  final Color color;

  const SessionListTile({
    super.key,
    required this.title,
    required this.location,
    required this.ascentsCount,
    required this.difficulty,
    required this.color,
  });

  @override
  ConsumerState<SessionListTile> createState() => _SessionListTileState();
}

class _SessionListTileState extends ConsumerState<SessionListTile> {
  void _openSessionDetails() {}

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: _openSessionDetails,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          height: 80.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Color(0xFF49454F), width: 1.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    spacing: 16.0,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(widget.location),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${widget.ascentsCount}'),
                          const Text('Ascents'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.difficulty.value,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Text('Max'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 8.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

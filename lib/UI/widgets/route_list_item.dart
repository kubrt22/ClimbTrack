import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:climb_track/UI/routes/route_details.dart';

class RouteListTile extends ConsumerStatefulWidget {
  final String id;

  final String title;
  final String location;
  final DateTime date;
  final ClimbType climbType;
  final Difficulty difficulty;
  final ClimbStyle? climbStyle;
  final Color color;

  const RouteListTile({
    super.key,
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.climbType,
    required this.climbStyle,
    required this.difficulty,
    required this.color,
  });

  @override
  ConsumerState<RouteListTile> createState() => _RouteListTileState();
}

class _RouteListTileState extends ConsumerState<RouteListTile> {
  void _openRouteDetails() {
    Navigator.push(
      ref.context,
      MaterialPageRoute(
        builder: (context) => RouteDetailsPage(routeId: widget.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: _openRouteDetails,
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(widget.climbType.name),
                          Text(
                            '${widget.date.day}.${widget.date.month}.${widget.date.year}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Ink(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                width: 80.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.difficulty.value),
                    Text(widget.climbStyle?.name ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:climb_track/UI/widgets/session_list_item.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';

@Preview(name: 'Session list item')
Widget sessionListTilePreview() {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SessionListTile(
            title: 'Morning session',
            location: 'Boulder Gym',
            ascentsCount: 12,
            difficulty: Difficulty(DifficultyType.UIAA, 'VII+'),
            color: Colors.orange,
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Route list item')
Widget routeListTilePreview() {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: RouteListTile(
            id: 'preview_route_id',
            title: 'The Nose',
            location: 'Yosemite',
            date: DateTime.now(),
            climbType: ClimbType.Lead,
            climbStyle: ClimbStyle.Onsight,
            difficulty: Difficulty(DifficultyType.UIAA, 'VIII-'),
            color: Colors.blue,
          ),
        ),
      ),
    ),
  );
}

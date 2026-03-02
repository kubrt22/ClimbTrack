import 'dart:developer';

import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/UI/routes/route_select.dart';
import 'package:climb_track/services/global_things.dart';

class SessionDetailsPage extends ConsumerStatefulWidget {
  const SessionDetailsPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends ConsumerState<SessionDetailsPage> {
  SessionModel? _session;

  @override
  void initState() {
    super.initState();
    _getRouteDetails();
  }

  void _getRouteDetails() {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);
    firestore
        .getSession(user.uid, widget.sessionId)
        .then((session) {
          if (session == null) {
            log("Session not found!");
            if (mounted) {
              showError(context, "Session nenalezena!");
              Navigator.pop(context);
            }
            return;
          }
          if (mounted) {
            setState(() {
              _session = session;
            });
          }
        })
        .catchError((e) {
          log("Error fetching session details: $e");
        });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Načítání...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final routesAsync = ref.watch(sessionRoutesProvider(session.routeIds));
    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          IconButton(
            onPressed: () {
              final user = ref.read(authStateProvider).value;
              if (user == null) return;
              final firestore = ref.read(firestoreServiceProvider);
              firestore.deleteSession(user.uid, session.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Místo",
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(session.location, style: TextStyle(fontSize: 18)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Datum",
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  "${session.date.day}.${session.date.month}.${session.date.year}",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Délka",
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  session.duration == null
                      ? 'Nezvoleno'
                      : '${session.duration!.hour}h ${session.duration!.minute}min',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Poznámky",
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(session.notes, style: TextStyle(fontSize: 18)),
              ],
            ),

            Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cesty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  routesAsync.value?.length.toString() ?? '0',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ],
            ),

            if (session.routeIds.isNotEmpty) _buildSelectedRoutes(routesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRoutes(AsyncValue routesAsync) {
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
      data: (routes) => ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 8.0),
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
    );
  }
}

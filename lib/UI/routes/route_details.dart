import 'dart:developer';

import 'package:climb_track/models/route_model.dart';
import 'package:flutter/material.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';

class RouteDetailsPage extends ConsumerStatefulWidget {
  const RouteDetailsPage({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends ConsumerState<RouteDetailsPage> {
  RouteModel? _route;

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
        .getRoute(user.uid, widget.routeId)
        .then((route) {
          if (route == null) {
            log("Route not found!");
            if (mounted) {
              showError(context, "Cesta nenalezena!");
              Navigator.pop(context);
            }
            return;
          }
          if (mounted) {
            setState(() {
              _route = route;
            });
          }
        })
        .catchError((e) {
          log("Error fetching route details: $e");
        });
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    if (route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Načítání...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(route.title),
        actions: [
          IconButton(
            onPressed: () {
              final user = ref.read(authStateProvider).value;
              if (user == null) return;
              final firestore = ref.read(firestoreServiceProvider);
              firestore.deleteRoute(user.uid, route.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              children: [
                Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Místo",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        Text(route.location, style: TextStyle(fontSize: 18)),
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
                          "${route.date.day}.${route.date.month}.${route.date.year}",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Obtížnost",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        Text(
                          route.difficulty.value,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Typ cesty",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        Text(
                          route.climbType.name,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),

                    if (route.climbStyle != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Styl",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            route.climbStyle!.name,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                  ],
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
                Text(route.notes, style: TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

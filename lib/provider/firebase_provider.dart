import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/services/firestore.dart';
import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/models/route_model.dart';
import 'package:climb_track/provider/auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final sessionsStreamProvider = StreamProvider<List<SessionModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).sessionsStream(user.uid);
});

final routesStreamProvider = StreamProvider<List<RouteModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).routesStream(user.uid);
});

// nechapu to lol
final sessionRoutesProvider =
    StreamProvider.family<List<RouteModel>, List<String>>((ref, routeIds) {
      final user = ref.watch(authStateProvider).value;
      if (user == null || routeIds.isEmpty) return Stream.value([]);
      return ref
          .watch(firestoreServiceProvider)
          .routesStreamForSession(user.uid, routeIds);
    });

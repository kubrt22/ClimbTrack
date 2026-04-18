import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:climb_track/models/route_model.dart';
import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/models/user_settings_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsRef(String uid) {
    try {
      return _db.collection('users').doc(uid).collection('settings').doc('app');
    } on FirebaseException catch (e) {
      log('Firestore error accessing settings document: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error accessing settings document: $e');
      rethrow;
    }
  }

  Stream<UserSettings> userSettingsStream(String uid) {
    return _settingsRef(uid)
        .snapshots()
        .handleError((error) {
          log('Error fetching user settings stream: $error');
        })
        .map((snap) {
          return UserSettings.fromMap(snap.data());
        });
  }

  Future<UserSettings> getUserSettings(String uid) async {
    try {
      final doc = await _settingsRef(uid).get();
      return UserSettings.fromMap(doc.data());
    } on FirebaseException catch (e) {
      log('Firestore error fetching user settings: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching user settings: $e');
      rethrow;
    }
  }

  Future<void> upsertUserSettings(String uid, UserSettings settings) async {
    try {
      await _settingsRef(uid).set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      log('Firestore error upserting user settings: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error upserting user settings: $e');
      rethrow;
    }
  }

  Future<void> patchUserSettings(String uid, Map<String, dynamic> patch) async {
    try {
      await _settingsRef(uid).set({
        ...patch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      log('Firestore error patching user settings: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error patching user settings: $e');
      rethrow;
    }
  }

  CollectionReference _sessionsRef(String uid) {
    try {
      return _db.collection('users').doc(uid).collection('sessions');
    } on FirebaseException catch (e) {
      log('Firestore error accessing sessions collection: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error accessing sessions collection: $e');
      rethrow;
    }
  }

  Stream<List<SessionModel>> sessionsStream(String uid) {
    return _sessionsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          log('Error fetching sessions stream: $error');
        })
        .map((snap) {
          try {
            return snap.docs
                .map((doc) => SessionModel.fromFirestore(doc))
                .toList();
          } catch (e) {
            log('Error parsing session documents: $e');
            return <SessionModel>[];
          }
        });
  }

  Future<SessionModel?> getSession(String uid, String sessionId) async {
    try {
      final doc = await _sessionsRef(uid).doc(sessionId).get();
      if (doc.exists) {
        return SessionModel.fromFirestore(doc);
      } else {
        log('Session with ID $sessionId not found for user $uid');
        return null;
      }
    } on FirebaseException catch (e) {
      log('Firestore error fetching session: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching session: $e');
      rethrow;
    }
  }

  Future<void> addSession(String uid, SessionModel session) async {
    try {
      await _sessionsRef(uid).add(session.toFirestore());
    } on FirebaseException catch (e) {
      log('Firestore error adding session: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error adding session: $e');
      rethrow;
    }
  }

  Future<void> updateSession(String uid, SessionModel session) async {
    try {
      await _sessionsRef(uid).doc(session.id).update(session.toFirestore());
    } on FirebaseException catch (e) {
      log('Firestore error updating session: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error updating session: $e');
      rethrow;
    }
  }

  Future<void> deleteSession(String uid, String sessionId) async {
    try {
      await _sessionsRef(uid).doc(sessionId).delete();
    } on FirebaseException catch (e) {
      log('Firestore error deleting session: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error deleting session: $e');
      rethrow;
    }
  }

  Future<List<SessionModel>> getAllSessions(String uid) async {
    try {
      final snap = await _sessionsRef(
        uid,
      ).orderBy('createdAt', descending: true).get();
      return snap.docs.map((doc) => SessionModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      log('Firestore error fetching all sessions: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching all sessions: $e');
      rethrow;
    }
  }

  Future<void> deleteAllSessions(String uid) async {
    try {
      final snap = await _sessionsRef(uid).get();
      await _deleteDocsInBatches(snap.docs);
    } on FirebaseException catch (e) {
      log('Firestore error deleting all sessions: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error deleting all sessions: $e');
      rethrow;
    }
  }

  Stream<List<RouteModel>> routesStreamForSession(
    String uid,
    List<String> routeIds,
  ) {
    try {
      return _routesRef(
        uid,
      ).where(FieldPath.documentId, whereIn: routeIds).snapshots().map((snap) {
        return snap.docs.map((doc) => RouteModel.fromFirestore(doc)).toList();
      });
    } on FirebaseException catch (e) {
      log('Firestore error fetching routes for session: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching routes for session: $e');
      rethrow;
    }
  }

  CollectionReference _routesRef(String uid) {
    try {
      return _db.collection('users').doc(uid).collection('routes');
    } on FirebaseException catch (e) {
      log('Firestore error accessing routes collection: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error accessing routes collection: $e');
      rethrow;
    }
  }

  Stream<List<RouteModel>> routesStream(String uid) {
    return _routesRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          log('Error fetching routes stream: $error');
        })
        .map((snap) {
          try {
            return snap.docs
                .map((doc) => RouteModel.fromFirestore(doc))
                .toList();
          } catch (e) {
            log('Error parsing route documents: $e');
            return <RouteModel>[];
          }
        });
  }

  Future<RouteModel?> getRoute(String uid, String routeId) async {
    try {
      final doc = await _routesRef(uid).doc(routeId).get();
      if (doc.exists) {
        return RouteModel.fromFirestore(doc);
      } else {
        log('Route with ID $routeId not found for user $uid');
        return null;
      }
    } on FirebaseException catch (e) {
      log('Firestore error fetching route: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching route: $e');
      rethrow;
    }
  }

  Future<void> addRoute(String uid, RouteModel route) async {
    try {
      await _routesRef(uid).add(route.toFirestore());
    } on FirebaseException catch (e) {
      log('Firestore error adding route: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error adding route: $e');
      rethrow;
    }
  }

  Future<void> updateRoute(String uid, RouteModel route) async {
    try {
      await _routesRef(uid).doc(route.id).update(route.toFirestore());
    } on FirebaseException catch (e) {
      log('Firestore error updating route: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error updating route: $e');
      rethrow;
    }
  }

  Future<void> deleteRoute(String uid, String routeId) async {
    try {
      await _routesRef(uid).doc(routeId).delete();
    } on FirebaseException catch (e) {
      log('Firestore error deleting route: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error deleting route: $e');
      rethrow;
    }
  }

  Future<List<RouteModel>> getAllRoutes(String uid) async {
    try {
      final snap = await _routesRef(
        uid,
      ).orderBy('createdAt', descending: true).get();
      return snap.docs.map((doc) => RouteModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      log('Firestore error fetching all routes: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching all routes: $e');
      rethrow;
    }
  }

  Future<void> deleteAllRoutes(String uid) async {
    try {
      final snap = await _routesRef(uid).get();
      await _deleteDocsInBatches(snap.docs);
    } on FirebaseException catch (e) {
      log('Firestore error deleting all routes: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error deleting all routes: $e');
      rethrow;
    }
  }

  Future<void> _deleteDocsInBatches(
    List<QueryDocumentSnapshot<Object?>> docs,
  ) async {
    const batchSize = 400;
    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = _db.batch();
      final end = i + batchSize > docs.length ? docs.length : i + batchSize;
      for (int j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
  }
}

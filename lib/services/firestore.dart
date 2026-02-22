import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:climb_track/models/route_model.dart';
import 'package:climb_track/models/session_model.dart';
import 'package:flutter/material.dart';
import 'package:climb_track/services/global_things.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
}

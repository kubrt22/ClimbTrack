import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:climb_track/models/friend_member_model.dart';
import 'package:climb_track/models/friend_request_model.dart';
import 'package:climb_track/models/route_model.dart';
import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/models/user_profile_model.dart';
import 'package:climb_track/models/user_settings_model.dart';
import 'package:climb_track/models/user_stats_model.dart';
import 'package:climb_track/services/global_things.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _db.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _friendRequestsRef() {
    return _db.collection('friend_requests');
  }

  DocumentReference<Map<String, dynamic>> _friendRequestRef(String requestId) {
    return _friendRequestsRef().doc(requestId);
  }

  DocumentReference<Map<String, dynamic>> _usernameRef(String usernameKey) {
    return _db.collection('usernames').doc(usernameKey);
  }

  String friendPairId(String uidA, String uidB) {
    return uidA.compareTo(uidB) < 0 ? '${uidA}_$uidB' : '${uidB}_$uidA';
  }

  String _normalizedUsername(String value) {
    return value.trim();
  }

  String _usernameKey(String value) {
    return _normalizedUsername(value).toLowerCase();
  }

  Future<void> _ensureUsernameIndexForUser({
    required String uid,
    required String username,
  }) async {
    final normalizedUsername = _normalizedUsername(username);
    final usernameKey = _usernameKey(username);
    if (normalizedUsername.isEmpty || usernameKey.isEmpty) return;

    final usernameRef = _usernameRef(usernameKey);
    final usernameDoc = await usernameRef.get();

    if (usernameDoc.exists) {
      final existingUid = (usernameDoc.data()?['uid'] ?? '').toString();
      if (existingUid == uid) return;

      log(
        'Username index conflict for "$normalizedUsername". Existing uid: $existingUid, current uid: $uid',
      );
      return;
    }

    await usernameRef.set({
      'uid': uid,
      'username': normalizedUsername,
      'usernameLower': usernameKey,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<List<T>> _chunksOf<T>(List<T> source, int chunkSize) {
    if (source.isEmpty) return const [];

    final chunks = <List<T>>[];
    for (int i = 0; i < source.length; i += chunkSize) {
      final end = i + chunkSize > source.length ? source.length : i + chunkSize;
      chunks.add(source.sublist(i, end));
    }
    return chunks;
  }

  List<String> _extractFriendUids(Map<String, dynamic>? data) {
    final raw = (data?['friends'] as List?) ?? const [];
    return raw
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> ensureUserDocument({
    required String uid,
    String? username,
  }) async {
    try {
      final userDoc = await _userRef(uid).get();
      final userData = userDoc.data();
      final statsData = userData?['stats'] as Map<String, dynamic>?;
      final hasStats = statsData != null && statsData.isNotEmpty;
      final friends = _extractFriendUids(userData);
      final hasFriendsField = userData?['friends'] is List;
      final existingUsername = (userData?['username'] ?? '').toString().trim();
      final normalizedIncomingUsername = _normalizedUsername(username ?? '');

      final patch = <String, dynamic>{};
      final shouldWriteUsername =
          normalizedIncomingUsername.isNotEmpty && existingUsername.isEmpty;

      if (shouldWriteUsername) {
        patch['username'] = normalizedIncomingUsername;
      }
      if (!hasFriendsField) {
        patch['friends'] = friends;
      }
      if (!hasStats) {
        patch['stats'] = {
          ...UserStatsModel.empty(uid).toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await _userRef(uid).set(patch, SetOptions(merge: true));
      }

      final usernameForIndex = normalizedIncomingUsername.isNotEmpty
          ? normalizedIncomingUsername
          : existingUsername;
      if (usernameForIndex.isNotEmpty) {
        try {
          await _ensureUsernameIndexForUser(
            uid: uid,
            username: usernameForIndex,
          );
        } catch (e) {
          log('Failed to sync username index for $uid: $e');
        }
      }
    } on FirebaseException catch (e) {
      log('Firestore error ensuring user document: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error ensuring user document: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    try {
      final key = _usernameKey(username);
      if (key.isEmpty) return true;

      final doc = await _usernameRef(key).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      log('Firestore error checking username availability: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error checking username availability: $e');
      rethrow;
    }
  }

  Future<void> reserveUsername({
    required String uid,
    required String username,
  }) async {
    try {
      final normalizedUsername = _normalizedUsername(username);
      final usernameKey = _usernameKey(username);
      if (normalizedUsername.isEmpty || usernameKey.isEmpty) {
        throw StateError('Username is required.');
      }

      await _db.runTransaction((tx) async {
        final usernameRef = _usernameRef(usernameKey);
        final usernameDoc = await tx.get(usernameRef);

        if (usernameDoc.exists) {
          final existingUid = (usernameDoc.data()?['uid'] ?? '').toString();
          if (existingUid != uid) {
            throw StateError('Username is already taken.');
          }
        }

        tx.set(usernameRef, {
          'uid': uid,
          'username': normalizedUsername,
          'usernameLower': usernameKey,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(_userRef(uid), {
          'username': normalizedUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } on FirebaseException catch (e) {
      log('Firestore error reserving username: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error reserving username: $e');
      rethrow;
    }
  }

  Stream<UserProfileModel?> watchUserProfile(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  Future<List<UserProfileModel>> searchUserProfilesByUsername({
    required String query,
    String? excludeUid,
    int limit = 12,
  }) async {
    try {
      final normalizedQuery = query.trim();
      if (normalizedQuery.isEmpty) return const <UserProfileModel>[];

      final usersSnap = await _db
          .collection('users')
          .orderBy('username')
          .startAt([normalizedQuery])
          .endAt(['$normalizedQuery\uf8ff'])
          .limit(limit)
          .get();

      final output = <UserProfileModel>[];
      final seenUids = <String>{};

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final uid = doc.id;
        final username = _normalizedUsername(
          (data['username'] ?? '').toString(),
        );
        if (uid.isEmpty) continue;
        if (username.isEmpty) continue;
        if (excludeUid != null && uid == excludeUid) continue;
        if (seenUids.contains(uid)) continue;

        final updatedAtValue = data['updatedAt'];
        final updatedAt = updatedAtValue is Timestamp
            ? updatedAtValue.toDate()
            : DateTime.now();

        output.add(
          UserProfileModel(uid: uid, username: username, updatedAt: updatedAt),
        );

        seenUids.add(uid);
      }

      return output;
    } on FirebaseException catch (e) {
      log('Firestore error searching users by username: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error searching users by username: $e');
      rethrow;
    }
  }

  Stream<UserStatsModel> userStatsStream(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      final data = doc.data();
      return UserStatsModel.fromMap(
        uid,
        data?['stats'] as Map<String, dynamic>?,
      );
    });
  }

  Future<UserStatsModel> getUserStats(String uid) async {
    try {
      final doc = await _userRef(uid).get();
      final data = doc.data();
      return UserStatsModel.fromMap(
        uid,
        data?['stats'] as Map<String, dynamic>?,
      );
    } on FirebaseException catch (e) {
      log('Firestore error fetching user stats: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error fetching user stats: $e');
      rethrow;
    }
  }

  double _routePoints(RouteModel route) {
    final base = route.difficulty.index + 1;

    final multiplier = switch (route.climbStyle) {
      ClimbStyle.Onsight => 1.5,
      ClimbStyle.Flash => 1.25,
      null => 1.0,
    };

    return base * multiplier;
  }

  Future<void> recalculateAndUpsertUserStats(String uid) async {
    try {
      final routes = await getAllRoutes(uid);
      final sessions = await getAllSessions(uid);

      final pointsByClimbType = <String, double>{
        for (final type in ClimbType.values) type.name: 0.0,
      };

      final hardestIndices = <String, int>{
        for (final type in DifficultyType.values) type.name: -1,
      };

      final hardestByDifficultyType = <String, String>{
        for (final type in DifficultyType.values) type.name: '-',
      };

      for (final route in routes) {
        final currentPoints = pointsByClimbType[route.climbType.name] ?? 0.0;
        pointsByClimbType[route.climbType.name] =
            currentPoints + _routePoints(route);

        final difficultyTypeName = route.difficulty.type.name;
        final previousIndex = hardestIndices[difficultyTypeName] ?? -1;
        if (route.difficulty.index > previousIndex) {
          hardestIndices[difficultyTypeName] = route.difficulty.index;
          hardestByDifficultyType[difficultyTypeName] = route.difficulty.value;
        }
      }

      await _userRef(uid).set({
        'stats': {
          'totalAscents': routes.length,
          'sessionsCount': sessions.length,
          'hardestByDifficultyType': hardestByDifficultyType,
          'pointsByClimbType': pointsByClimbType,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      log('Firestore error recalculating user stats: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error recalculating user stats: $e');
      rethrow;
    }
  }

  Future<void> sendFriendRequestByUid({
    required String fromUid,
    required String fromUsername,
    required String targetUid,
    required String targetUsername,
  }) async {
    try {
      final normalizedFromUsername = _normalizedUsername(fromUsername);
      final normalizedTargetUsername = _normalizedUsername(targetUsername);

      if (normalizedFromUsername.isEmpty || normalizedTargetUsername.isEmpty) {
        throw StateError('Missing username for friend request.');
      }

      if (targetUid == fromUid) {
        throw StateError('You cannot add yourself.');
      }

      final requestId = friendPairId(fromUid, targetUid);
      final fromDoc = await _userRef(fromUid).get();
      final targetDoc = await _userRef(targetUid).get();

      final fromFriends = _extractFriendUids(fromDoc.data());
      final targetFriends = _extractFriendUids(targetDoc.data());
      if (fromFriends.contains(targetUid) || targetFriends.contains(fromUid)) {
        throw StateError('You are already friends.');
      }

      final requestRef = _friendRequestRef(requestId);
      final requestDoc = await requestRef.get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data();
        final status = (requestData?['status'] ?? '').toString();
        final existingFromUid = (requestData?['fromUid'] ?? '').toString();
        final existingToUid = (requestData?['toUid'] ?? '').toString();

        if (status == FriendRequestStatus.pending.name) {
          if (existingFromUid == fromUid && existingToUid == targetUid) {
            throw StateError('Friend request already sent.');
          }

          if (existingFromUid == targetUid && existingToUid == fromUid) {
            throw StateError(
              'This user already sent you a friend request. Accept it first.',
            );
          }
        }

        if (status == FriendRequestStatus.accepted.name) {
          throw StateError('You are already friends.');
        }

        await requestRef.delete();
      }

      await requestRef.set({
        'fromUid': fromUid,
        'toUid': targetUid,
        'fromUsername': normalizedFromUsername,
        'toUsername': normalizedTargetUsername,
        'status': FriendRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      log('Firestore error sending friend request: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error sending friend request: $e');
      rethrow;
    }
  }

  Future<void> acceptFriendRequest({
    required String currentUid,
    required String requestId,
  }) async {
    try {
      final requestRef = _friendRequestRef(requestId);
      final requestDoc = await requestRef.get();
      final requestData = requestDoc.data();

      if (!requestDoc.exists || requestData == null) {
        throw StateError('Friend request not found.');
      }

      final fromUid = (requestData['fromUid'] ?? '').toString();
      final toUid = (requestData['toUid'] ?? '').toString();
      final status = (requestData['status'] ?? '').toString();

      if (toUid != currentUid) {
        throw StateError('You cannot accept this request.');
      }
      if (status != FriendRequestStatus.pending.name) {
        throw StateError('Friend request is no longer pending.');
      }

      await _db.runTransaction((tx) async {
        final fromRef = _userRef(fromUid);
        final toRef = _userRef(toUid);
        final txFromDoc = await tx.get(fromRef);
        final txToDoc = await tx.get(toRef);

        final fromFriends = _extractFriendUids(txFromDoc.data());
        final toFriends = _extractFriendUids(txToDoc.data());

        if (!fromFriends.contains(toUid)) {
          fromFriends.add(toUid);
        }
        if (!toFriends.contains(fromUid)) {
          toFriends.add(fromUid);
        }

        tx.update(requestRef, {
          'status': FriendRequestStatus.accepted.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(fromRef, {
          'friends': fromFriends,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(toRef, {
          'friends': toFriends,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } on FirebaseException catch (e) {
      log('Firestore error accepting friend request: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error accepting friend request: $e');
      rethrow;
    }
  }

  Future<void> rejectFriendRequest({
    required String currentUid,
    required String requestId,
  }) async {
    try {
      final requestRef = _friendRequestRef(requestId);
      final requestDoc = await requestRef.get();
      final requestData = requestDoc.data();

      if (!requestDoc.exists || requestData == null) {
        throw StateError('Friend request not found.');
      }

      final toUid = (requestData['toUid'] ?? '').toString();
      final status = (requestData['status'] ?? '').toString();

      if (toUid != currentUid) {
        throw StateError('You cannot reject this request.');
      }
      if (status != FriendRequestStatus.pending.name) {
        throw StateError('Friend request is no longer pending.');
      }

      await requestRef.update({
        'status': FriendRequestStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      log('Firestore error rejecting friend request: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error rejecting friend request: $e');
      rethrow;
    }
  }

  Stream<List<FriendRequestModel>> watchIncomingFriendRequests(String uid) {
    return _friendRequestsRef().where('toUid', isEqualTo: uid).snapshots().map((
      snap,
    ) {
      final requests = snap.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc))
          .where((request) => request.status == FriendRequestStatus.pending)
          .toList();

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<FriendRequestModel>> watchOutgoingFriendRequests(String uid) {
    return _friendRequestsRef()
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final requests = snap.docs
              .map((doc) => FriendRequestModel.fromFirestore(doc))
              .where((request) => request.status == FriendRequestStatus.pending)
              .toList();

          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Stream<List<String>> _watchFriendUids(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      return _extractFriendUids(doc.data());
    });
  }

  Future<Map<String, UserProfileModel>> _getProfilesByUids(
    List<String> uids,
  ) async {
    final deduped = uids.toSet().toList();
    final output = <String, UserProfileModel>{};

    for (final chunk in _chunksOf(deduped, 10)) {
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        output[doc.id] = UserProfileModel.fromFirestore(doc);
      }
    }

    return output;
  }

  Future<Map<String, UserStatsModel>> _getStatsByUids(List<String> uids) async {
    final deduped = uids.toSet().toList();
    final output = <String, UserStatsModel>{};

    for (final chunk in _chunksOf(deduped, 10)) {
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        output[doc.id] = UserStatsModel.fromMap(
          doc.id,
          data['stats'] as Map<String, dynamic>?,
        );
      }
    }

    return output;
  }

  Stream<List<FriendMemberModel>> watchFriendsWithStats(
    String uid, {
    bool includeSelf = false,
  }) {
    return _watchFriendUids(uid).asyncMap((friendUids) async {
      final allUids = <String>[...friendUids];
      if (includeSelf && !allUids.contains(uid)) {
        allUids.add(uid);
      }

      if (allUids.isEmpty) return <FriendMemberModel>[];

      final profileMap = await _getProfilesByUids(allUids);
      final statsMap = await _getStatsByUids(allUids);

      final output = <FriendMemberModel>[];
      for (final friendUid in allUids) {
        final profile = profileMap[friendUid];
        if (profile == null) continue;

        final stats = statsMap[friendUid] ?? UserStatsModel.empty(friendUid);
        output.add(FriendMemberModel(profile: profile, stats: stats));
      }

      return output;
    });
  }

  Stream<List<FriendMemberModel>> watchFriendsLeaderboard(
    String uid,
    ClimbType climbType,
  ) {
    return watchFriendsWithStats(uid, includeSelf: true).map((members) {
      final sorted = List<FriendMemberModel>.from(members);
      sorted.sort((a, b) {
        final byPoints = b.stats
            .pointsForClimbType(climbType)
            .compareTo(a.stats.pointsForClimbType(climbType));
        if (byPoints != 0) return byPoints;

        final byAscents = b.stats.totalAscents.compareTo(a.stats.totalAscents);
        if (byAscents != 0) return byAscents;

        return a.profile.username.toLowerCase().compareTo(
          b.profile.username.toLowerCase(),
        );
      });
      return sorted;
    });
  }

  Future<bool> canViewUserProfile({
    required String viewerUid,
    required String targetUid,
  }) async {
    if (viewerUid == targetUid) return true;

    final viewerDoc = await _userRef(viewerUid).get();
    final viewerFriends = _extractFriendUids(viewerDoc.data());
    return viewerFriends.contains(targetUid);
  }

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
      await recalculateAndUpsertUserStats(uid);
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
      await recalculateAndUpsertUserStats(uid);
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
      await recalculateAndUpsertUserStats(uid);
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
      await recalculateAndUpsertUserStats(uid);
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
      await recalculateAndUpsertUserStats(uid);
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
      await recalculateAndUpsertUserStats(uid);
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
      await recalculateAndUpsertUserStats(uid);
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

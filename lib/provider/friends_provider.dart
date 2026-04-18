import 'package:climb_track/models/friend_member_model.dart';
import 'package:climb_track/models/friend_request_model.dart';
import 'package:climb_track/models/user_profile_model.dart';
import 'package:climb_track/models/user_stats_model.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendsTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    if (state == index) return;
    state = index;
  }
}

final friendsTabIndexProvider = NotifierProvider<FriendsTabIndexNotifier, int>(
  FriendsTabIndexNotifier.new,
);

class LeaderboardClimbTypeNotifier extends Notifier<ClimbType> {
  @override
  ClimbType build() => ClimbType.Boulder;

  void setType(ClimbType climbType) {
    state = climbType;
  }
}

final leaderboardClimbTypeProvider =
    NotifierProvider<LeaderboardClimbTypeNotifier, ClimbType>(
      LeaderboardClimbTypeNotifier.new,
    );

final currentUserProfileProvider = StreamProvider<UserProfileModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreServiceProvider).watchUserProfile(user.uid);
});

final currentUserStatsProvider = StreamProvider<UserStatsModel>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(UserStatsModel.empty(''));

  return ref.watch(firestoreServiceProvider).userStatsStream(user.uid);
});

final incomingFriendRequestsProvider = StreamProvider<List<FriendRequestModel>>(
  (ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return Stream.value(const <FriendRequestModel>[]);

    return ref
        .watch(firestoreServiceProvider)
        .watchIncomingFriendRequests(user.uid);
  },
);

final outgoingFriendRequestsProvider = StreamProvider<List<FriendRequestModel>>(
  (ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return Stream.value(const <FriendRequestModel>[]);

    return ref
        .watch(firestoreServiceProvider)
        .watchOutgoingFriendRequests(user.uid);
  },
);

final friendsMembersProvider = StreamProvider<List<FriendMemberModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <FriendMemberModel>[]);

  return ref.watch(firestoreServiceProvider).watchFriendsWithStats(user.uid);
});

final friendsLeaderboardProvider = StreamProvider<List<FriendMemberModel>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <FriendMemberModel>[]);

  final selectedClimbType = ref.watch(leaderboardClimbTypeProvider);
  return ref
      .watch(firestoreServiceProvider)
      .watchFriendsLeaderboard(user.uid, selectedClimbType);
});

final canViewUserProfileProvider = FutureProvider.family<bool, String>((
  ref,
  targetUid,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  return ref
      .watch(firestoreServiceProvider)
      .canViewUserProfile(viewerUid: user.uid, targetUid: targetUid);
});

final userProfileByUidProvider =
    StreamProvider.family<UserProfileModel?, String>((ref, targetUid) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return Stream.value(null);

      return ref.watch(firestoreServiceProvider).watchUserProfile(targetUid);
    });

final userStatsByUidProvider = StreamProvider.family<UserStatsModel, String>((
  ref,
  targetUid,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(UserStatsModel.empty(targetUid));

  return ref.watch(firestoreServiceProvider).userStatsStream(targetUid);
});

class FriendsController {
  FriendsController(this.ref);

  final Ref ref;

  User? _currentUser() {
    return ref.read(authStateProvider).value ??
        FirebaseAuth.instance.currentUser;
  }

  String _authUsernameCandidate() {
    final user = _currentUser();
    if (user == null) return '';

    final displayName = user.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user.email?.trim() ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return '';
  }

  Future<void> ensureCurrentUserDocument() async {
    final user = _currentUser();
    if (user == null) return;

    await ref
        .read(firestoreServiceProvider)
        .ensureUserDocument(uid: user.uid, username: _authUsernameCandidate());
  }

  Future<void> refreshMyStats() async {
    final user = _currentUser();
    if (user == null) return;

    await ref
        .read(firestoreServiceProvider)
        .recalculateAndUpsertUserStats(user.uid);
  }

  Future<List<UserProfileModel>> searchUserProfilesByUsername(
    String query,
  ) async {
    final user = _currentUser();
    if (user == null) return const <UserProfileModel>[];

    return ref
        .read(firestoreServiceProvider)
        .searchUserProfilesByUsername(query: query, excludeUid: user.uid);
  }

  Future<void> sendFriendRequestToUser({
    required String targetUid,
    required String targetUsername,
  }) async {
    final user = _currentUser();
    if (user == null) return;

    final profile = ref.read(currentUserProfileProvider).asData?.value;
    final profileUsername = profile?.username.trim() ?? '';
    final fromUsername = profileUsername.isNotEmpty
        ? profileUsername
        : _authUsernameCandidate();

    if (fromUsername.isEmpty) {
      throw StateError('Missing current username. Please sign in again.');
    }

    await ref
        .read(firestoreServiceProvider)
        .sendFriendRequestByUid(
          fromUid: user.uid,
          fromUsername: fromUsername,
          targetUid: targetUid,
          targetUsername: targetUsername,
        );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final user = _currentUser();
    if (user == null) return;

    await ref
        .read(firestoreServiceProvider)
        .acceptFriendRequest(currentUid: user.uid, requestId: requestId);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final user = _currentUser();
    if (user == null) return;

    await ref
        .read(firestoreServiceProvider)
        .rejectFriendRequest(currentUid: user.uid, requestId: requestId);
  }
}

final friendsControllerProvider = Provider<FriendsController>((ref) {
  return FriendsController(ref);
});

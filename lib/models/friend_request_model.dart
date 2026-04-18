import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromUsername;
  final String toUsername;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromUsername,
    required this.toUsername,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final createdAtValue = data?['createdAt'];
    final updatedAtValue = data?['updatedAt'];

    return FriendRequestModel(
      id: doc.id,
      fromUid: (data?['fromUid'] ?? '').toString(),
      toUid: (data?['toUid'] ?? '').toString(),
      fromUsername: (data?['fromUsername'] ?? '').toString(),
      toUsername: (data?['toUsername'] ?? '').toString(),
      status: _statusFromName((data?['status'] ?? 'pending').toString()),
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      updatedAt: updatedAtValue is Timestamp
          ? updatedAtValue.toDate()
          : DateTime.now(),
    );
  }

  static FriendRequestStatus _statusFromName(String name) {
    for (final status in FriendRequestStatus.values) {
      if (status.name == name) return status;
    }
    return FriendRequestStatus.pending;
  }
}

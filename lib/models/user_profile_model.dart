import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String username;
  final DateTime updatedAt;

  UserProfileModel({
    required this.uid,
    required this.username,
    required this.updatedAt,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserProfileModel.fromMap(doc.id, data);
  }

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic>? data) {
    final updatedAtValue = data?['updatedAt'];
    final updatedAt = updatedAtValue is Timestamp
        ? updatedAtValue.toDate()
        : DateTime.now();

    return UserProfileModel(
      uid: uid,
      username: (data?['username'] ?? '').toString(),
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {'username': username, 'updatedAt': Timestamp.fromDate(updatedAt)};
  }
}

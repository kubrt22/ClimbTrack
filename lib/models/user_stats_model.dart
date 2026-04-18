import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:climb_track/services/global_things.dart';

class UserStatsModel {
  final String uid;
  final int totalAscents;
  final int sessionsCount;
  final Map<String, String> hardestByDifficultyType;
  final Map<String, double> pointsByClimbType;
  final DateTime updatedAt;

  UserStatsModel({
    required this.uid,
    required this.totalAscents,
    required this.sessionsCount,
    required this.hardestByDifficultyType,
    required this.pointsByClimbType,
    required this.updatedAt,
  });

  factory UserStatsModel.empty(String uid) {
    return UserStatsModel(
      uid: uid,
      totalAscents: 0,
      sessionsCount: 0,
      hardestByDifficultyType: {
        for (final type in DifficultyType.values) type.name: '-',
      },
      pointsByClimbType: {for (final type in ClimbType.values) type.name: 0.0},
      updatedAt: DateTime.now(),
    );
  }

  factory UserStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserStatsModel.fromMap(doc.id, data);
  }

  factory UserStatsModel.fromMap(String uid, Map<String, dynamic>? data) {
    final updatedAtValue = data?['updatedAt'];
    final updatedAt = updatedAtValue is Timestamp
        ? updatedAtValue.toDate()
        : DateTime.now();

    final hardestRaw = (data?['hardestByDifficultyType'] as Map?) ?? {};
    final pointsRaw = (data?['pointsByClimbType'] as Map?) ?? {};

    final hardestByDifficultyType = <String, String>{
      for (final type in DifficultyType.values)
        type.name: (hardestRaw[type.name] ?? '-').toString(),
    };

    final pointsByClimbType = <String, double>{
      for (final type in ClimbType.values)
        type.name: ((pointsRaw[type.name] as num?) ?? 0).toDouble(),
    };

    return UserStatsModel(
      uid: uid,
      totalAscents: ((data?['totalAscents'] as num?) ?? 0).toInt(),
      sessionsCount: ((data?['sessionsCount'] as num?) ?? 0).toInt(),
      hardestByDifficultyType: hardestByDifficultyType,
      pointsByClimbType: pointsByClimbType,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAscents': totalAscents,
      'sessionsCount': sessionsCount,
      'hardestByDifficultyType': hardestByDifficultyType,
      'pointsByClimbType': pointsByClimbType,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  double pointsForClimbType(ClimbType climbType) {
    return pointsByClimbType[climbType.name] ?? 0;
  }

  String hardestForDifficultyType(DifficultyType difficultyType) {
    return hardestByDifficultyType[difficultyType.name] ?? '-';
  }
}

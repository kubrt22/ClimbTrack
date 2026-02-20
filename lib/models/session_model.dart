import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  // Hidden
  final String id;
  final DateTime createdAt;

  // Visible
  final String title;
  final String location;
  final int durationMinutes;
  final String notes;
  final List<String> routeIds;

  SessionModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.location,
    required this.durationMinutes,
    this.notes = '',
    this.routeIds = const [],
  });

  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      notes: data['notes'] ?? '',
      routeIds: List<String>.from(data['routeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'routeIds': routeIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SessionModel {
  // Hidden
  final String id;
  final DateTime createdAt;

  // Visible
  final String title;
  final String location;
  final DateTime date;
  final TimeOfDay? duration;
  final String notes;
  final List<String> routeIds;

  SessionModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.location,
    required this.date,
    required this.duration,
    this.notes = '',
    this.routeIds = const [],
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      duration: data['durationMinutes'] == null
          ? null
          : TimeOfDay(
              hour: (data['durationMinutes'] as int) ~/ 60,
              minute: (data['durationMinutes'] as int) % 60,
            ),
      notes: data['notes'] ?? '',
      routeIds: List<String>.from(data['routeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      'date': Timestamp.fromDate(date),
      'durationMinutes': duration == null
          ? null
          : duration!.hour * 60 + duration!.minute,
      'notes': notes,
      'routeIds': routeIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

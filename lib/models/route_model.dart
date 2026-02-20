import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';

//- TODO: Images

class RouteModel {
  // Hidden
  final String id;
  final DateTime createdAt;

  // Visible
  final String title;
  final String location;
  final DateTime date;
  final ClimbType climbType;
  final ClimbStyle climbStyle;
  final Difficulty difficulty;
  final int routeColor;
  final List<Image> images;
  final String notes;

  RouteModel({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.climbType,
    required this.climbStyle,
    required this.difficulty,
    required this.routeColor,
    this.images = const [],
    required this.createdAt,
    this.notes = '',
  });

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      climbType: ClimbType.values.byName(data['climbType']),
      climbStyle: ClimbStyle.values.byName(data['climbStyle']),
      difficulty: Difficulty(
        DifficultyType.values.byName(data['difficultyType']),
        data['difficultyValue'] ?? '',
      ),
      routeColor: data['routeColor'] ?? 0xFF2196F3,
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'title': title,
      'location': location,
      'date': Timestamp.fromDate(date),
      'climbType': climbType.name,
      'climbStyle': climbStyle.name,
      'difficultyType': difficulty.type.name,
      'difficultyValue': difficulty.value,
      'routeColor': routeColor,
      'notes': notes,
    };
  }
}

import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

enum DifficultyType { UIAA, French, V_Scale, Font }

const Map<DifficultyType, List<String>> difficultyValues = {
  DifficultyType.UIAA: [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI-',
    'VI',
    'VI+',
    'VII-',
    'VII',
    'VII+',
    'VIII-',
    'VIII',
    'VIII+',
    'IX-',
    'IX',
    'IX+',
    'X-',
    'X',
    'X+',
    'XI-',
    'XI',
    'XI+',
    'XII-',
    'XII',
  ],
  DifficultyType.French: [
    '1',
    '2',
    '3',
    '4a',
    '4b',
    '4c',
    '5a',
    '5b',
    '5c',
    '6a',
    '6a+',
    '6b',
    '6b+',
    '6c',
    '6c+',
    '7a',
    '7a+',
    '7b',
    '7b+',
    '7c',
    '7c+',
    '8a',
    '8a+',
    '8b',
    '8b+',
    '8c',
    '8c+',
    '9a',
    '9a+',
    '9b',
    '9b+',
    '9c',
  ],
  DifficultyType.V_Scale: [
    'V0',
    'V1',
    'V2',
    'V3',
    'V4',
    'V5',
    'V6',
    'V7',
    'V8',
    'V9',
    'V10',
    'V11',
    'V12',
    'V13',
    'V14',
    'V15',
    'V16',
    'V17',
  ],
  DifficultyType.Font: [
    '4',
    '4+',
    '5',
    '5+',
    '6A',
    '6A+',
    '6B',
    '6B+',
    '6C',
    '6C+',
    '7A',
    '7A+',
    '7B',
    '7B+',
    '7C',
    '7C+',
    '8A',
    '8A+',
    '8B',
    '8B+',
    '8C',
    '8C+',
    '9A',
  ],
};

class Difficulty {
  final DifficultyType type;
  final String value;

  Difficulty(this.type, this.value);

  int get index => difficultyValues[type]!.indexOf(value);

  /// Display-friendly type name
  String get typeName {
    switch (type) {
      case DifficultyType.UIAA:
        return 'UIAA';
      case DifficultyType.French:
        return 'French';
      case DifficultyType.V_Scale:
        return 'V-Scale';
      case DifficultyType.Font:
        return 'Font';
    }
  }
}

enum ClimbType { Boulder, Toprope, Lead }

enum ClimbStyle { Onsight, Flash }

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red[900]),
  );
}

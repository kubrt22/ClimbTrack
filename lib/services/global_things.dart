// ignore: constant_identifier_names
enum DifficultyType { UIAA, French, V_Scale, Font }

class Difficulty {
  final DifficultyType type;
  final String value;

  Difficulty(this.type, this.value);
}

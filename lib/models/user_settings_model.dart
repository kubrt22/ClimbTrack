import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';

enum AppThemeSetting { system, light, dark }

enum OverviewSortSetting { newestFirst, oldestFirst, titleAZ, locationAZ }

class UserSettings {
  final AppThemeSetting themeMode;
  final DifficultyType defaultDifficultyType;
  final Color preferredRouteStartColor;
  final OverviewSortSetting sessionsSort;
  final OverviewSortSetting routesSort;

  const UserSettings({
    required this.themeMode,
    required this.defaultDifficultyType,
    required this.preferredRouteStartColor,
    required this.sessionsSort,
    required this.routesSort,
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      themeMode: AppThemeSetting.dark,
      defaultDifficultyType: DifficultyType.V_Scale,
      preferredRouteStartColor: Colors.black,
      sessionsSort: OverviewSortSetting.newestFirst,
      routesSort: OverviewSortSetting.newestFirst,
    );
  }

  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    final defaults = UserSettings.defaults();
    if (map == null) return defaults;

    return UserSettings(
      themeMode: _enumFromName(
        AppThemeSetting.values,
        map['themeMode'],
        defaults.themeMode,
      ),
      defaultDifficultyType: _enumFromName(
        DifficultyType.values,
        map['defaultDifficultyType'],
        defaults.defaultDifficultyType,
      ),
      preferredRouteStartColor: _colorFromRaw(
        map['preferredRouteStartColor'],
        defaults.preferredRouteStartColor,
      ),
      sessionsSort: _enumFromName(
        OverviewSortSetting.values,
        map['sessionsSort'],
        defaults.sessionsSort,
      ),
      routesSort: _enumFromName(
        OverviewSortSetting.values,
        map['routesSort'],
        defaults.routesSort,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'defaultDifficultyType': defaultDifficultyType.name,
      'preferredRouteStartColor': preferredRouteStartColor.toARGB32(),
      'sessionsSort': sessionsSort.name,
      'routesSort': routesSort.name,
    };
  }

  UserSettings copyWith({
    AppThemeSetting? themeMode,
    DifficultyType? defaultDifficultyType,
    Color? preferredRouteStartColor,
    OverviewSortSetting? sessionsSort,
    OverviewSortSetting? routesSort,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultDifficultyType:
          defaultDifficultyType ?? this.defaultDifficultyType,
      preferredRouteStartColor:
          preferredRouteStartColor ?? this.preferredRouteStartColor,
      sessionsSort: sessionsSort ?? this.sessionsSort,
      routesSort: routesSort ?? this.routesSort,
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, dynamic raw, T fallback) {
  if (raw is! String) return fallback;
  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  return fallback;
}

Color _colorFromRaw(dynamic raw, Color fallback) {
  if (raw is int) {
    return Color(raw);
  }
  if (raw is num) {
    return Color(raw.toInt());
  }
  return fallback;
}

extension AppThemeSettingLabel on AppThemeSetting {
  String get label {
    switch (this) {
      case AppThemeSetting.system:
        return 'Systém';
      case AppThemeSetting.light:
        return 'Světlý';
      case AppThemeSetting.dark:
        return 'Tmavý';
    }
  }
}

extension OverviewSortSettingLabel on OverviewSortSetting {
  String get label {
    switch (this) {
      case OverviewSortSetting.newestFirst:
        return 'Nejnovější';
      case OverviewSortSetting.oldestFirst:
        return 'Nejstarší';
      case OverviewSortSetting.titleAZ:
        return 'Název A-Z';
      case OverviewSortSetting.locationAZ:
        return 'Místo A-Z';
    }
  }
}

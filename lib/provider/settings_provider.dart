import 'package:climb_track/models/user_settings_model.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userSettingsProvider = StreamProvider<UserSettings>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(UserSettings.defaults());

  return ref.watch(firestoreServiceProvider).userSettingsStream(user.uid);
});

final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeMode = ref
      .watch(userSettingsProvider)
      .maybeWhen(
        data: (settings) => settings.themeMode,
        orElse: () => AppThemeSetting.dark,
      );

  switch (themeMode) {
    case AppThemeSetting.system:
      return ThemeMode.system;
    case AppThemeSetting.light:
      return ThemeMode.light;
    case AppThemeSetting.dark:
      return ThemeMode.dark;
  }
});

class UserSettingsController {
  UserSettingsController(this.ref);

  final Ref ref;

  Future<void> _patch(Map<String, dynamic> patch) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    await ref.read(firestoreServiceProvider).patchUserSettings(user.uid, patch);
  }

  Future<void> setThemeMode(AppThemeSetting themeMode) {
    return _patch({'themeMode': themeMode.name});
  }

  Future<void> setDefaultDifficultyType(DifficultyType difficultyType) {
    return _patch({'defaultDifficultyType': difficultyType.name});
  }

  Future<void> setPreferredRouteStartColor(Color color) {
    return _patch({'preferredRouteStartColor': color.toARGB32()});
  }

  Future<void> setSessionsSort(OverviewSortSetting sort) {
    return _patch({'sessionsSort': sort.name});
  }

  Future<void> setRoutesSort(OverviewSortSetting sort) {
    return _patch({'routesSort': sort.name});
  }
}

final userSettingsControllerProvider = Provider<UserSettingsController>((ref) {
  return UserSettingsController(ref);
});

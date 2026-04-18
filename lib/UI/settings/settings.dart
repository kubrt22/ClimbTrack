import 'package:climb_track/UI/settings/settings_account.dart';
import 'package:climb_track/UI/settings/settings_appearance.dart';
import 'package:climb_track/UI/settings/settings_data.dart';
import 'package:climb_track/UI/settings/settings_preferences.dart';
import 'package:climb_track/UI/widgets/settings_list_item.dart';
import 'package:climb_track/models/user_settings_model.dart';
import 'package:climb_track/provider/settings_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveSettings = ref
        .watch(userSettingsProvider)
        .maybeWhen(data: (settings) => settings, orElse: UserSettings.defaults);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Obecné', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SettingsListItem(
          icon: Icons.palette_outlined,
          title: 'Vzhled',
          subtitle: 'Motiv: ${effectiveSettings.themeMode.label}',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsAppearancePage(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SettingsListItem(
          icon: Icons.tune_rounded,
          title: 'Preference',
          subtitle:
              'Default: ${Difficulty(effectiveSettings.defaultDifficultyType, '').typeName}',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPreferencesPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SettingsListItem(
          icon: Icons.manage_accounts_outlined,
          title: 'Účet',
          subtitle: 'Přihlášení, reset hesla, odhlášení',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsAccountPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SettingsListItem(
          icon: Icons.storage_rounded,
          title: 'Data',
          subtitle: 'Export a správa dat',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsDataPage()),
            );
          },
        ),
      ],
    );
  }
}

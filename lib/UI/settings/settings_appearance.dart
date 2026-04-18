import 'package:climb_track/models/user_settings_model.dart';
import 'package:climb_track/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAppearancePage extends ConsumerWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vzhled')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Motiv aplikace',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<AppThemeSetting>(
                selected: {settings.themeMode},
                segments: AppThemeSetting.values
                    .map(
                      (mode) =>
                          ButtonSegment(value: mode, label: Text(mode.label)),
                    )
                    .toList(),
                onSelectionChanged: (selected) {
                  final mode = selected.first;
                  ref
                      .read(userSettingsControllerProvider)
                      .setThemeMode(mode)
                      .catchError((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nepodařilo se uložit motiv'),
                          ),
                        );
                      });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

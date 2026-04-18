import 'package:climb_track/models/user_settings_model.dart';
import 'package:climb_track/provider/settings_provider.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPreferencesPage extends ConsumerWidget {
  const SettingsPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dropdownFieldTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
    final dropdownMenuStyle = MenuStyle(
      maximumSize: const WidgetStatePropertyAll(Size.fromHeight(280)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Preference')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (settings) {
          Future<void> pickPreferredColor() async {
            Color tempColor = settings.preferredRouteStartColor;
            final pickedColor = await showDialog<Color>(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      title: const Text('Výchozí barva cesty'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: tempColor,
                          onColorChanged: (color) {
                            setDialogState(() {
                              tempColor = color;
                            });
                          },
                          enableAlpha: false,
                          displayThumbColor: true,
                          labelTypes: const [],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Zrušit'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, tempColor),
                          style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          child: const Text('Vybrat'),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (pickedColor == null) return;
            await ref
                .read(userSettingsControllerProvider)
                .setPreferredRouteStartColor(pickedColor)
                .catchError((_) {
                  if (!context.mounted) return;
                  showError(context, 'Nepodařilo se uložit barvu');
                });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Výchozí obtížnost',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Theme(
                    data: dropdownFieldTheme,
                    child: DropdownMenu<DifficultyType>(
                      width: constraints.maxWidth,
                      initialSelection: settings.defaultDifficultyType,
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      menuStyle: dropdownMenuStyle,
                      trailingIcon: const Icon(Icons.keyboard_arrow_down_sharp),
                      selectedTrailingIcon: const Icon(
                        Icons.keyboard_arrow_up_sharp,
                      ),
                      dropdownMenuEntries: DifficultyType.values
                          .map(
                            (type) => DropdownMenuEntry(
                              value: type,
                              label: Difficulty(type, '').typeName,
                            ),
                          )
                          .toList(),
                      onSelected: (value) {
                        if (value == null) return;
                        ref
                            .read(userSettingsControllerProvider)
                            .setDefaultDifficultyType(value)
                            .catchError((_) {
                              if (!context.mounted) return;
                              showError(
                                context,
                                'Nepodařilo se uložit preferenci',
                              );
                            });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Výchozí barva cesty',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(
                    const Size(double.infinity, 56),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  alignment: Alignment.centerLeft,
                  shape: const WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                onPressed: pickPreferredColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nastavit výchozí barvu',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: settings.preferredRouteStartColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Řazení přehledu session',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Theme(
                    data: dropdownFieldTheme,
                    child: DropdownMenu<OverviewSortSetting>(
                      width: constraints.maxWidth,
                      initialSelection: settings.sessionsSort,
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      menuStyle: dropdownMenuStyle,
                      trailingIcon: const Icon(Icons.keyboard_arrow_down_sharp),
                      selectedTrailingIcon: const Icon(
                        Icons.keyboard_arrow_up_sharp,
                      ),
                      dropdownMenuEntries: OverviewSortSetting.values
                          .map(
                            (sort) => DropdownMenuEntry(
                              value: sort,
                              label: sort.label,
                            ),
                          )
                          .toList(),
                      onSelected: (value) {
                        if (value == null) return;
                        ref
                            .read(userSettingsControllerProvider)
                            .setSessionsSort(value)
                            .catchError((_) {
                              if (!context.mounted) return;
                              showError(context, 'Nepodařilo se uložit řazení');
                            });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Řazení přehledu cest',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Theme(
                    data: dropdownFieldTheme,
                    child: DropdownMenu<OverviewSortSetting>(
                      width: constraints.maxWidth,
                      initialSelection: settings.routesSort,
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      menuStyle: dropdownMenuStyle,
                      trailingIcon: const Icon(Icons.keyboard_arrow_down_sharp),
                      selectedTrailingIcon: const Icon(
                        Icons.keyboard_arrow_up_sharp,
                      ),
                      dropdownMenuEntries: OverviewSortSetting.values
                          .map(
                            (sort) => DropdownMenuEntry(
                              value: sort,
                              label: sort.label,
                            ),
                          )
                          .toList(),
                      onSelected: (value) {
                        if (value == null) return;
                        ref
                            .read(userSettingsControllerProvider)
                            .setRoutesSort(value)
                            .catchError((_) {
                              if (!context.mounted) return;
                              showError(context, 'Nepodařilo se uložit řazení');
                            });
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:convert';

import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDataPage extends ConsumerStatefulWidget {
  const SettingsDataPage({super.key});

  @override
  ConsumerState<SettingsDataPage> createState() => _SettingsDataPageState();
}

class _SettingsDataPageState extends ConsumerState<SettingsDataPage> {
  bool _busy = false;

  Future<void> _exportData() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final firestore = ref.read(firestoreServiceProvider);
      final sessions = await firestore.getAllSessions(user.uid);
      final routes = await firestore.getAllRoutes(user.uid);

      final export = {
        'exportedAt': DateTime.now().toIso8601String(),
        'uid': user.uid,
        'sessions': sessions
            .map(
              (s) => {
                'id': s.id,
                'title': s.title,
                'location': s.location,
                'date': s.date.toIso8601String(),
                'durationMinutes': s.duration == null
                    ? null
                    : s.duration!.hour * 60 + s.duration!.minute,
                'notes': s.notes,
                'routeIds': s.routeIds,
                'createdAt': s.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'routes': routes
            .map(
              (r) => {
                'id': r.id,
                'title': r.title,
                'location': r.location,
                'date': r.date.toIso8601String(),
                'climbType': r.climbType.name,
                'climbStyle': r.climbStyle?.name,
                'difficultyType': r.difficulty.type.name,
                'difficultyValue': r.difficulty.value,
                'routeColor': r.routeColor.toARGB32(),
                'notes': r.notes,
                'createdAt': r.createdAt.toIso8601String(),
              },
            )
            .toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(export);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Export dat'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(child: SelectableText(json)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: json));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Export zkopírován do schránky'),
                    ),
                  );
                },
                child: const Text('Kopírovat'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: const ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                child: const Text('Zavřít'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteAllData() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Smazat všechna data?'),
          content: const Text(
            'Tato akce smaže všechny session i cesty a nejde vrátit zpět.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: const ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
              child: const Text('Smazat vše'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.deleteAllSessions(user.uid);
      await firestore.deleteAllRoutes(user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Všechna data byla smazána')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _exportData,
            style: appButtonStyle,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Exportovat data (JSON)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _deleteAllData,
            style: appButtonStyle,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Smazat všechna data'),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: export je zobrazen v dialogu a lze jej zkopírovat do schránky.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

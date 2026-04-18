import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/UI/widgets/settings_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAccountPage extends ConsumerStatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  ConsumerState<SettingsAccountPage> createState() =>
      _SettingsAccountPageState();
}

class _SettingsAccountPageState extends ConsumerState<SettingsAccountPage> {
  bool _busy = false;

  Future<void> _sendResetEmail() async {
    if (_busy) return;
    final user = ref.read(authStateProvider).value;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Účet nemá e-mail pro reset hesla')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset hesla odeslán na $email')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final appButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Účet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsListItem(
            icon: Icons.person_outline_rounded,
            title: 'Uživatelské jméno',
            subtitle: user?.displayName ?? 'Nezadáno',
          ),
          const SizedBox(height: 8),
          SettingsListItem(
            icon: Icons.alternate_email_rounded,
            title: 'E-mail',
            subtitle: user?.email ?? 'Nezadáno',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _sendResetEmail,
            style: appButtonStyle,
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Poslat reset hesla'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _signOut,
            style: appButtonStyle,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Odhlásit se'),
          ),
        ],
      ),
    );
  }
}

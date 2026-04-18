import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/UI/widgets/settings_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountUsernameProvider = StreamProvider.family<String?, String>((
  ref,
  uid,
) {
  return ref.watch(firestoreServiceProvider).watchUserProfile(uid).map((
    profile,
  ) {
    final username = profile?.username.trim() ?? '';
    if (username.isEmpty) return null;
    return username;
  });
});

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
      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(authStateProvider).value ?? FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    final authUsernameFallback = displayName.isNotEmpty
        ? displayName
        : 'Nezadáno';

    final usernameAsync = user == null
        ? const AsyncValue<String?>.data(null)
        : ref.watch(accountUsernameProvider(user.uid));

    final usernameSubtitle = user == null
        ? 'Nezadáno'
        : usernameAsync.when(
            data: (username) {
              final value = username?.trim() ?? '';
              if (value.isNotEmpty) return value;
              return authUsernameFallback;
            },
            loading: () {
              if (displayName.isNotEmpty) return displayName;
              return 'Načítám...';
            },
            error: (_, __) => authUsernameFallback,
          );

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
            subtitle: usernameSubtitle,
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red[900]),
  );
}

Future<void> signIn({
  required BuildContext context,
  required WidgetRef ref,
  required String email,
  required String password,
  required Function(bool) setLoading,
}) async {
  if (email.isEmpty || password.isEmpty) {
    showError(context, 'Please fill in all fields');
    return;
  }

  final auth = ref.read(authServiceProvider);
  setLoading(true);

  try {
    await auth.signInWithEmail(email.trim(), password.trim());

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  } catch (e) {
    if (context.mounted) {
      showError(context, '$e');
    }
  } finally {
    setLoading(false);
  }
}

Future<void> register({
  required BuildContext context,
  required WidgetRef ref,
  required String email,
  required String password,
  required String confirmPassword,
  required String username,
  required Function(bool) setLoading,
}) async {
  if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
    showError(context, 'Please fill in all fields');
    return;
  }

  if (password != confirmPassword) {
    showError(context, 'Passwords do not match');
    return;
  }

  final auth = ref.read(authServiceProvider);
  setLoading(true);

  try {
    await auth.registerWithEmail(
      email.trim(),
      password.trim(),
      username.trim(),
    );

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      showError(context, '$e');
    }
  } finally {
    setLoading(false);
  }
}

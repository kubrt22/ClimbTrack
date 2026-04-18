import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/services/global_things.dart';

String _resolvedUsername({required User? user, String? preferredUsername}) {
  final preferred = preferredUsername?.trim() ?? '';
  if (preferred.isNotEmpty) return preferred;

  final displayName = user?.displayName?.trim() ?? '';
  return displayName;
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
    final credential = await auth.signInWithEmail(
      email.trim(),
      password.trim(),
    );
    final signedInUser = credential.user;
    if (signedInUser != null) {
      await ref
          .read(firestoreServiceProvider)
          .ensureUserDocument(
            uid: signedInUser.uid,
            username: _resolvedUsername(user: signedInUser),
          );
    }

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
  if (email.isEmpty ||
      password.isEmpty ||
      confirmPassword.isEmpty ||
      username.isEmpty) {
    showError(context, 'Please fill in all fields');
    return;
  }

  if (password != confirmPassword) {
    showError(context, 'Passwords do not match');
    return;
  }

  final auth = ref.read(authServiceProvider);
  final firestore = ref.read(firestoreServiceProvider);
  setLoading(true);

  try {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      if (context.mounted) {
        showError(context, 'Username cannot be empty');
      }
      return;
    }

    final usernameTaken = await firestore.isUsernameTaken(normalizedUsername);
    if (usernameTaken) {
      if (context.mounted) {
        showError(context, 'Username is already taken');
      }
      return;
    }

    final credential = await auth.registerWithEmail(
      email.trim(),
      password.trim(),
      normalizedUsername,
    );

    final registeredUser = credential.user;
    if (registeredUser != null) {
      try {
        await firestore.reserveUsername(
          uid: registeredUser.uid,
          username: normalizedUsername,
        );
        await firestore.ensureUserDocument(
          uid: registeredUser.uid,
          username: _resolvedUsername(
            user: registeredUser,
            preferredUsername: normalizedUsername,
          ),
        );
      } catch (_) {
        try {
          await registeredUser.delete();
        } catch (_) {}
        rethrow;
      }
    }

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      showError(context, '$e');
    }
  } on StateError catch (e) {
    if (context.mounted) {
      showError(context, '${e.message}');
    }
  } catch (e) {
    if (context.mounted) {
      showError(context, '$e');
    }
  } finally {
    setLoading(false);
  }
}

Future<void> resetPassword({
  required BuildContext context,
  required WidgetRef ref,
  required String email,
}) async {
  if (email.isEmpty) {
    showError(context, 'Please enter your email');
    return;
  }

  final auth = ref.read(authServiceProvider);

  try {
    await auth.sendPasswordResetEmail(email.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Password reset email sent')));
    }
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      showError(context, '$e');
    }
  }
}

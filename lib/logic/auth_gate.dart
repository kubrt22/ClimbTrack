import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/UI/overview.dart';
import 'package:climb_track/UI/login/welcome.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Overview();
    // ignore: dead_code
    final userAsync = ref.watch(authStateProvider);
    if (userAsync.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userAsync.value != null) {
      return Overview();
    } else {
      return const WelcomeScreen();
    }
  }
}

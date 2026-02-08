import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';

class Overview extends ConsumerWidget {
  const Overview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String value = "Hello world";
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text(value)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginWidget extends ConsumerWidget {
  const LoginWidget({
    this.title = 'ClimbTrack',
    this.subtitle = '',
    this.children = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(40, 160, 40, 0),
        child: Column(
          spacing: 30,

          children: [
            Text(
              title,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(subtitle, style: TextStyle(fontSize: 32)),
            SizedBox(height: 10),
            FilledButtonTheme(
              data: FilledButtonThemeData(style: loginButtonStyle),
              child: Column(spacing: 20, children: children),
            ),
          ],
        ),
      ),
    );
  }

  static const ButtonStyle loginButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(double.infinity, 60)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 24)),
  );
}

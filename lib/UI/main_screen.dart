import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:climb_track/UI/widgets/navigation.dart';
import 'package:climb_track/UI/overview.dart';
import 'package:climb_track/UI/settings/settings.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        return OverviewPage.buildAppBar(ref);
      case 1:
        return AppBar(title: const Text('Přátelé'));
      case 2:
        return AppBar(title: const Text('Nastavení'));
      default:
        return AppBar();
    }
  }

  FloatingActionButton? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0:
        return OverviewPage.buildFAB(ref);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      bottomNavigationBar: Navigation(
        currentIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),

      floatingActionButton: _buildFloatingActionButton(),
      body: <Widget>[
        // - Home page
        OverviewPage(),

        // - Friends page
        Container(child: const Center(child: Text('Přátelé'))),

        // - Settings page
        SettingsPage(),
      ][_currentIndex],
    );
  }
}

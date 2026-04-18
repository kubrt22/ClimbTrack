import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:climb_track/UI/widgets/navigation.dart';
import 'package:climb_track/UI/friends/friends_page.dart';
import 'package:climb_track/UI/overview.dart';
import 'package:climb_track/UI/settings/settings.dart';
import 'package:climb_track/provider/riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  TextEditingController? _overviewSearchController;
  FocusNode? _overviewSearchFocusNode;
  Timer? _overviewSearchDebounce;
  DateTime? _overviewSearchCloseAt;
  int _searchFocusRequestId = 0;
  bool _isOverviewSearchOpen = false;

  TextEditingController get _searchController {
    return _overviewSearchController ??= TextEditingController(
      text: ref.read(overviewSearchQueryProvider),
    );
  }

  FocusNode get _searchFocusNode {
    final existing = _overviewSearchFocusNode;
    if (existing != null) return existing;

    final created = FocusNode();
    created.addListener(_onSearchFocusChanged);
    _overviewSearchFocusNode = created;
    return created;
  }

  @override
  void initState() {
    super.initState();
    _isOverviewSearchOpen = false;
  }

  @override
  void dispose() {
    _overviewSearchDebounce?.cancel();
    _overviewSearchFocusNode?.removeListener(_onSearchFocusChanged);
    _overviewSearchFocusNode?.dispose();
    _overviewSearchController?.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index != 0 && _isOverviewSearchOpen) {
      _closeOverviewSearch();
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    final hasFocus = _overviewSearchFocusNode?.hasFocus ?? false;

    // Only auto-collapse on focus loss. Expansion is always explicit via search icon.
    if (!hasFocus) {
      _collapseOverviewSearch();
    }
  }

  void _collapseOverviewSearch() {
    _searchFocusRequestId += 1;
    _overviewSearchCloseAt = DateTime.now();

    if (!_isOverviewSearchOpen) return;
    setState(() {
      _isOverviewSearchOpen = false;
    });
  }

  void _applyOverviewSearch(String value) {
    final normalized = value.trim();
    _overviewSearchDebounce?.cancel();
    _overviewSearchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final currentQuery = ref.read(overviewSearchQueryProvider);
      if (currentQuery == normalized) return;
      ref.read(overviewSearchQueryProvider.notifier).setQuery(normalized);
    });
  }

  void _openOverviewSearch() {
    final closedAt = _overviewSearchCloseAt;
    if (closedAt != null &&
        DateTime.now().difference(closedAt) <
            const Duration(milliseconds: 300)) {
      return;
    }

    if (_isOverviewSearchOpen &&
        (_overviewSearchFocusNode?.hasFocus ?? false)) {
      return;
    }

    final currentQuery = ref.read(overviewSearchQueryProvider);
    if (_overviewSearchController == null) {
      _overviewSearchController = TextEditingController(text: currentQuery);
    } else if (_overviewSearchController!.text != currentQuery) {
      _overviewSearchController!.text = currentQuery;
      _overviewSearchController!.selection = TextSelection.collapsed(
        offset: _overviewSearchController!.text.length,
      );
    }

    setState(() {
      _isOverviewSearchOpen = true;
    });

    _searchFocusRequestId += 1;
    final requestId = _searchFocusRequestId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOverviewSearchOpen) return;
      if (requestId != _searchFocusRequestId) return;
      final focusNode = _overviewSearchFocusNode;
      if (focusNode == null || focusNode.hasFocus) return;
      focusNode.requestFocus();
    });
  }

  void _closeOverviewSearch({bool clear = false}) {
    _overviewSearchDebounce?.cancel();
    _overviewSearchFocusNode?.unfocus();
    if (clear) {
      _overviewSearchController?.clear();
      ref.read(overviewSearchQueryProvider.notifier).clear();
    }
    _collapseOverviewSearch();
  }

  void _clearOverviewSearch() {
    if (_isOverviewSearchOpen) {
      _closeOverviewSearch(clear: true);
      return;
    }

    _overviewSearchDebounce?.cancel();
    _overviewSearchController?.clear();
    ref.read(overviewSearchQueryProvider.notifier).clear();
    setState(() {});
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        final hasActiveSearch = ref
            .watch(overviewSearchQueryProvider)
            .trim()
            .isNotEmpty;

        if (_isOverviewSearchOpen) {
          return AppBar(
            titleSpacing: 0,
            leading: IconButton(
              onPressed: _closeOverviewSearch,
              tooltip: 'Zpět',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Filtr session a cest',
                border: InputBorder.none,
              ),
              onTapOutside: (_) => _overviewSearchFocusNode?.unfocus(),
              onChanged: _applyOverviewSearch,
              onSubmitted: (value) {
                _applyOverviewSearch(value);
                _overviewSearchFocusNode?.unfocus();
              },
            ),
            actions: [
              IconButton(
                onPressed: _clearOverviewSearch,
                tooltip: 'Vymazat filtr',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          );
        }

        return AppBar(
          title: const Text('Přehled'),
          actions: [
            IconButton(
              onPressed: _openOverviewSearch,
              tooltip: hasActiveSearch ? 'Hledat (aktivní filtr)' : 'Hledat',
              icon: Icon(
                hasActiveSearch
                    ? Icons.manage_search_rounded
                    : Icons.search_rounded,
              ),
            ),
            if (hasActiveSearch)
              IconButton(
                onPressed: _clearOverviewSearch,
                tooltip: 'Zrušit filtr',
                icon: const Icon(Icons.filter_alt_off_rounded),
              ),
          ],
        );
      case 1:
        return FriendsPage.buildAppBar(ref);
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
      case 1:
        return FriendsPage.buildFAB(ref);
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
        FriendsPage(),

        // - Settings page
        SettingsPage(),
      ][_currentIndex],
    );
  }
}

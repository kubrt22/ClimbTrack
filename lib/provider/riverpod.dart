import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverviewTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final overviewTabIndexProvider = NotifierProvider<OverviewTabNotifier, int>(
  OverviewTabNotifier.new,
);

class OverviewSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final overviewSearchQueryProvider =
    NotifierProvider<OverviewSearchQueryNotifier, String>(
      OverviewSearchQueryNotifier.new,
    );

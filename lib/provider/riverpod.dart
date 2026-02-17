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

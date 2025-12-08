import 'package:flutter_riverpod/flutter_riverpod.dart';

// State to hold the current Site ID
class SiteContextNotifier extends Notifier<int?> {
  @override
  int? build() {
    return null;
  }

  void setSiteId(int? id) {
    state = id;
  }

  void clearSite() {
    state = null;
  }
}

final siteContextProvider = NotifierProvider<SiteContextNotifier, int?>(
  SiteContextNotifier.new,
);

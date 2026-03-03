import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';

/// Bridge between Riverpod auth state and GoRouter's [refreshListenable].
///
/// GoRouter requires a [Listenable] to trigger route re-evaluation.
/// This notifier watches the [authNotifierProvider] and fires
/// [notifyListeners] whenever the auth state changes.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

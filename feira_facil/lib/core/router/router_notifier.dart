import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../../features/auth/data/auth_repository.dart';

/// A notifier that triggers its listeners whenever the auth state or user profile changes.
/// This is used by GoRouter to re-evaluate the redirect logic.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to auth state changes
    _ref.listen(authStateChangesProvider, (previous, next) {
      debugPrint('RouterNotifier: AuthState changed');
      notifyListeners();
    });
    
    // Listen to user profile changes (important for groupId detection)
    _ref.listen(currentUserProfileProvider, (previous, next) {
      debugPrint('RouterNotifier: Profile changed');
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

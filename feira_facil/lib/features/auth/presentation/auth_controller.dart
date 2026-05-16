import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
      
      final user = authRepo.currentUser;
      if (user != null) {
        await ref.read(userRepositoryProvider).ensureUserExists(
          userId: user.uid,
          email: user.email ?? '',
          name: user.displayName,
        );
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).signOut();
    });
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final userId = authRepo.currentUser?.uid;

      if (userId != null) {
        // 1. Delete Firestore data first
        await userRepo.deleteUserData(userId);
        // 2. Delete Auth account
        await authRepo.deleteAccount();
      }
    });
  }
}

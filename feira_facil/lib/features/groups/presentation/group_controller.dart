import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/family_group.dart';

final groupControllerProvider = AsyncNotifierProvider<GroupController, FamilyGroup?>(() {
  return GroupController();
});

class GroupController extends AsyncNotifier<FamilyGroup?> {
  @override
  FutureOr<FamilyGroup?> build() {
    return null;
  }

  Future<void> createFamilyGroup(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Usuário não logado');
      
      final group = await ref.read(groupRepositoryProvider).createGroup(name, user.uid);
      return group;
    });
  }

  Future<void> joinFamilyGroup(String inviteCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Usuário não logado');

      final group = await ref.read(groupRepositoryProvider).joinGroup(inviteCode.toUpperCase(), user.uid);
      return group;
    });
  }
}

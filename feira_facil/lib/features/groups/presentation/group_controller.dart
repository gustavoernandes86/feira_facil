import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../domain/family_group.dart';

// Re-exporta o provider canônico de grupo (definido em user_providers.dart)
export 'package:feira_facil/core/providers/user_providers.dart' show currentGroupIdProvider;

/// Provider do usuário autenticado atualmente
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

/// Stream dos grupos do usuário
final userGroupsStreamProvider = StreamProvider<List<FamilyGroup>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(groupRepositoryProvider);
  return repository.userGroupsStream(user.uid);
});

/// Controller para gerenciar grupos
final groupControllerProvider = AsyncNotifierProvider<GroupController, void>(
  () => GroupController(),
);

class GroupController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  /// Cria um novo grupo familiar
  Future<void> createGroup(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Usuário não autenticado');

      final repository = ref.read(groupRepositoryProvider);
      // createGroup já persiste groupIds no Firestore, o router reage automaticamente
      await repository.createGroup(name, user.uid);

      // Invalida o provider de streams
      ref.invalidate(userGroupsStreamProvider);
    });
  }

  /// Adiciona o usuário a um grupo pelo código de convite
  Future<void> joinGroupByCode(String inviteCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Usuário não autenticado');

      final repository = ref.read(groupRepositoryProvider);
      final group = await repository.joinGroup(inviteCode, user.uid);
      if (group == null) throw Exception('Código de convite inválido');

      // Invalida o provider de streams — router redireciona automaticamente
      ref.invalidate(userGroupsStreamProvider);
    });
  }

  /// Sai do grupo (remove o usuário do grupo)
  Future<void> leaveGroup(String groupId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Usuário não autenticado');

      final repository = ref.read(groupRepositoryProvider);
      await repository.removeMemberFromGroup(groupId, user.uid);

      // Invalida o provider de streams
      ref.invalidate(userGroupsStreamProvider);
    });
  }

  /// Obtém o código de convite do grupo
  Future<String?> getGroupInviteCode(String groupId) async {
    final repository = ref.read(groupRepositoryProvider);
    final group = await repository.getGroup(groupId);
    return group?.inviteCode;
  }

  /// Admin: exclui o grupo inteiro
  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Usuário não autenticado');
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      ref.invalidate(userGroupsStreamProvider);
    });
  }

  /// Admin: remove um membro específico do grupo
  Future<void> removeMember(String groupId, String memberId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(groupRepositoryProvider).removeMemberFromGroup(groupId, memberId);
      ref.invalidate(userGroupsStreamProvider);
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/groups/data/group_repository.dart';
import '../../features/groups/domain/family_group.dart';

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  
  return authAsync.when(
    data: (authUser) {
      if (authUser == null) return Stream.value(null);
      final userRepo = ref.watch(userRepositoryProvider);
      return userRepo.watchUser(authUser.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err, stack),
  );
});

final currentGroupIdProvider = Provider<String?>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  // Prioriza o último grupo acessado, se não houver, pega o primeiro da lista
  return userProfile?.lastGroupId ?? 
         (userProfile?.groupIds.isNotEmpty == true ? userProfile!.groupIds.first : null);
});

final currentGroupStreamProvider = StreamProvider<FamilyGroup?>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  if (groupId == null) return Stream.value(null);
  
  final groupRepo = ref.watch(groupRepositoryProvider);
  return groupRepo.watchGroup(groupId);
});

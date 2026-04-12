import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/groups/presentation/group_setup_screen.dart';
import '../../features/groups/presentation/group_management_screen.dart';
import '../../features/feiras/presentation/feiras_screen.dart';
import '../../features/feiras/presentation/feira_items_screen.dart';
import '../../features/feiras/domain/feira.dart';
import '../../features/markets/presentation/markets_screen.dart';
import 'router_notifier.dart';

// Constantes de rota
class RouteNames {
  static const login = 'login';
  static const groupSetup = 'groupSetup';
  static const groupManagement = 'groupManagement';
  static const feiras = 'feiras';
  static const feiraDetails = 'feiraDetails';
  static const markets = 'markets';
}

class RoutePaths {
  static const login = '/login';
  static const groupSetup = '/group-setup';
  static const groupManagement = '/group-management';
  static const feiras = '/feiras';
  static const markets = '/markets';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final profileAsync = ref.read(currentUserProfileProvider);
      
      final authState = authAsync.value;
      final userProfile = profileAsync.value;
      
      final isLoggingIn = state.matchedLocation == RoutePaths.login;

      debugPrint('--- ROUTER REDIRECT ---');
      debugPrint('Path: ${state.matchedLocation}');
      debugPrint('Auth (loading=${authAsync.isLoading}): ${authState?.uid}');

      // Se não estiver logado, obriga a ir para a tela de login
      if (authState == null) {
        debugPrint('Redirect: User not logged in');
        return isLoggingIn ? null : RoutePaths.login;
      }

      // 2. Se estiver logado e na tela de login, decide para onde ir
      if (isLoggingIn) {
        if (authState != null) {
          debugPrint('Redirect: Logged in detected -> Forcing Home');
          return RoutePaths.feiras;
        }
        
        if (authAsync.isLoading) {
          debugPrint('Wait: Auth is still loading...');
          return null;
        }
        
        return null;
      }

      // 3. Se estiver no Setup mas já estiver logado, permite ir para Home se quiser
      if (state.matchedLocation == RoutePaths.groupSetup && authState != null) {
        // Se já tiver grupos, não deixa ficar no Setup
        if (userProfile != null && userProfile.groupIds.isNotEmpty) {
           debugPrint('Redirect: Found groups, leaving Setup');
           return RoutePaths.feiras;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.groupSetup,
        name: RouteNames.groupSetup,
        builder: (context, state) => const GroupSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.groupManagement,
        name: RouteNames.groupManagement,
        builder: (context, state) => const GroupManagementScreen(),
      ),
      GoRoute(
        path: RoutePaths.feiras,
        name: RouteNames.feiras,
        builder: (context, state) => const FeirasScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: RouteNames.feiraDetails,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final feira = state.extra as Feira?;
              return FeiraItemsScreen(feiraId: id, feiraContext: feira);
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.markets,
        name: RouteNames.markets,
        builder: (context, state) => const MarketsScreen(),
      ),
    ],
  );
});

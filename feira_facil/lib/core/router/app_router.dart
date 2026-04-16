import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
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
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const groupSetup = 'groupSetup';
  static const groupManagement = 'groupManagement';
  static const feiras = 'feiras';
  static const feiraDetails = 'feiraDetails';
  static const markets = 'markets';
}

class RoutePaths {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const groupSetup = '/group-setup';
  static const groupManagement = '/group-management';
  static const feiras = '/feiras';
  static const markets = '/markets';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final profileAsync = ref.read(currentUserProfileProvider);
      
      final authState = authAsync.value;
      final userProfile = profileAsync.value;
      
      final isSplash = state.matchedLocation == RoutePaths.splash;
      final isOnboarding = state.matchedLocation == RoutePaths.onboarding;
      final isLoggingIn = state.matchedLocation == RoutePaths.login;

      // Se for Splash ou Onboarding, não redireciona por enquanto
      if (isSplash || isOnboarding) return null;

      // Se não estiver logado, obriga a ir para a tela de login
      if (authState == null) {
        return isLoggingIn ? null : RoutePaths.login;
      }

      // Se estiver logado e na tela de login, redireciona para home
      if (isLoggingIn) {
        return RoutePaths.feiras;
      }

      // Se estiver no Setup mas já tiver grupo, permite ir para Home
      if (state.matchedLocation == RoutePaths.groupSetup) {
        if (userProfile != null && userProfile.groupIds.isNotEmpty) {
           return RoutePaths.feiras;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
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

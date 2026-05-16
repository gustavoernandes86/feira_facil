import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/legal_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/groups/presentation/group_setup_screen.dart';
import '../../features/groups/presentation/settings_screen.dart';
import '../../features/groups/presentation/group_management_screen.dart';
import '../../features/markets/presentation/markets_screen.dart';
import '../../features/markets/presentation/market_detail_screen.dart';
import '../../features/markets/domain/market.dart';
import '../../features/lists/presentation/lists_screen.dart';
import '../../features/lists/presentation/list_items_screen.dart';
import '../../features/lists/presentation/list_comparison_screen.dart';
import '../../features/lists/presentation/suggested_purchases_screen.dart';
import '../../features/lists/presentation/savings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/lists/domain/fair_list.dart';
import '../../features/lists/domain/list_item.dart';
import 'router_notifier.dart';

// Constantes de rota
class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const groupSetup = 'groupSetup';
  static const groupManagement = 'groupManagement'; // kept for legacy nav
  static const settings = 'settings';
  static const markets = 'markets';
  static const marketDetails = 'marketDetails';
  static const suggestedPurchases = 'suggestedPurchases';
  static const lists = 'lists';
  static const listDetails = 'listDetails';
  static const listCompare = 'listCompare';
  static const savings = 'savings';
  static const notifications = 'notifications';
  static const privacyPolicy = 'privacyPolicy';
  static const termsOfUse = 'termsOfUse';
}

class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const groupSetup = '/group-setup';
  static const groupManagement = '/group-management';
  static const settings = '/settings';
  static const markets = '/markets';
  static const lists = '/lists';
  static const notifications = '/notifications';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfUse = '/terms-of-use';
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
      final isLoggingIn = state.matchedLocation == RoutePaths.login;
      final isGroupSetup = state.matchedLocation == RoutePaths.groupSetup;
      final isPrivacyPolicy = state.matchedLocation == RoutePaths.privacyPolicy;
      final isTermsOfUse = state.matchedLocation == RoutePaths.termsOfUse;

      // 1. Se não estiver logado
      if (authState == null) {
        // Permite ficar nas telas públicas (splash, login, privacidade, termos)
        if (isSplash || isLoggingIn || isPrivacyPolicy || isTermsOfUse) {
          return null;
        }
        // Obriga a ir para login
        return RoutePaths.login;
      }

      // 2. A partir daqui, o usuário ESTÁ logado.
      // Se ele estiver nas telas iniciais, precisamos redirecioná-lo para dentro do app.
      if (isSplash || isLoggingIn) {
        // Se o perfil carregou e não tem grupos, manda para setup
        if (userProfile != null && userProfile.groupIds.isEmpty) {
          return RoutePaths.groupSetup;
        }
        // Se ainda está carregando ou já tem grupos, vai para lists
        return RoutePaths.lists;
      }

      // 3. Se estiver no Setup mas JÁ TIVER grupo, não precisa ficar lá
      if (isGroupSetup) {
        if (userProfile != null && userProfile.groupIds.isNotEmpty) {
           return RoutePaths.lists;
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
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/group-management',
        name: 'group-management',
        builder: (context, state) => const GroupManagementScreen(),
      ),

      GoRoute(
        path: RoutePaths.markets,
        name: RouteNames.markets,
        builder: (context, state) => const MarketsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: RouteNames.marketDetails,
            builder: (context, state) {
              final market = state.extra as Market;
              return MarketDetailScreen(market: market);
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.lists,
        name: RouteNames.lists,
        builder: (context, state) => const ListsScreen(),
        routes: [
          GoRoute(
            path: 'compare',
            name: RouteNames.listCompare,
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>?;
              return ListComparisonScreen(
                fairList: data?['fairList'] as FairList?,
                items: data?['items'] as List<ListItem>?,
                marketIds: data?['marketIds'] as List<String>?,
              );
            },
          ),
          GoRoute(
            path: 'suggested',
            name: RouteNames.suggestedPurchases,
            builder: (context, state) => const SuggestedPurchasesScreen(),
          ),
          GoRoute(
            path: 'savings',
            name: RouteNames.savings,
            builder: (context, state) => const SavingsScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.listDetails,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final list = state.extra as FairList?;
              return ListItemsScreen(listId: id, listContext: list);
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacyPolicy,
        name: RouteNames.privacyPolicy,
        builder: (context, state) => const LegalScreen(type: LegalType.privacyPolicy),
      ),
      GoRoute(
        path: RoutePaths.termsOfUse,
        name: RouteNames.termsOfUse,
        builder: (context, state) => const LegalScreen(type: LegalType.termsOfUse),
      ),
    ],
  );
});

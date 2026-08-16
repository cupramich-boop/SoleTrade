import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/home/category_products_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/search_screen.dart';
import '../../screens/legal/privacy_screen.dart';
import '../../screens/legal/terms_screen.dart';
import '../../screens/product/add_product_screen.dart';
import '../../screens/product/edit_product_screen.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/root/root_scaffold.dart';
import '../supabase/supabase_client.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(_authRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final publicRoutes = {'/welcome', '/login', '/register'};
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);
      final isLegalRoute =
          state.matchedLocation == '/terms' ||
          state.matchedLocation == '/privacy';

      if (!loggedIn && !isPublicRoute && !isLegalRoute) return '/welcome';
      if (loggedIn && isPublicRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add-product',
                builder: (context, state) => const AddProductScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id/edit',
        builder: (context, state) =>
            EditProductScreen(product: state.extra as Product),
      ),
      GoRoute(
        path: '/category',
        builder: (context, state) =>
            CategoryProductsScreen(category: state.extra as SoleCategory),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) =>
            ChatScreen(chatId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Odświeża router, gdy zmienia się stan uwierzytelnienia Supabase.
final _authRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final stream = ref.watch(authStateProvider.stream);
  final refresh = GoRouterRefreshStream(stream);
  ref.onDispose(refresh.dispose);
  return refresh;
});

/// Konwertuje strumień zdarzeń Supabase Auth na Listenable dla go_router.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

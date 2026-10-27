import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/catalog_screen.dart';
import 'presentation/home_shell.dart';
import 'presentation/review_detail_screen.dart';
import 'presentation/review_form_screen.dart';
import 'presentation/reviews_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createMobileRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, state) => const CatalogScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/reviews', builder: (context, state) => const ReviewsScreen())],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reviews/new',
        builder: (context, state) => const ReviewFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reviews/:id',
        builder: (context, state) => ReviewDetailScreen(reviewId: state.pathParameters['id']!),
      ),
    ],
  );
}

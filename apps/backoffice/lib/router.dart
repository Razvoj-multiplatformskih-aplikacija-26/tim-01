import 'package:go_router/go_router.dart';

import 'presentation/moderation_screen.dart';

GoRouter createBackofficeRouter() {
  return GoRouter(
    initialLocation: '/reviews',
    routes: [GoRoute(path: '/reviews', builder: (context, state) => const ModerationScreen())],
  );
}

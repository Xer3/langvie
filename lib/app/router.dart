import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/onboarding/placement_test_screen.dart';

import '../features/home/home_screen.dart';
import '../features/home/shell_screen.dart';

import '../features/lessons/chapter_list_screen.dart';
import '../features/lessons/chapter_detail_screen.dart';

import '../features/flashcards/flashcards_screen.dart';
import '../features/ai_assistant/ai_assistant_screen.dart';
import '../features/settings/settings_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<AppState>(appStateProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final s = ref.read(appStateProvider);
      if (!s.isReady) return null;

      final loc = state.uri.toString();
      final inSplash = loc.startsWith('/splash');
      final inAuth = loc.startsWith('/auth');
      final inOnboarding = loc.startsWith('/onboarding/');

      // Splash zawsze dozwolony (sam przejdzie do /home)
      if (inSplash) return null;

      if (!s.isLoggedIn) {
        return inAuth ? null : '/auth';
      }

      // ✅ onboarding tylko po rejestracji — od razu test (bez language pickera)
      if (s.needsOnboarding) {
        return inOnboarding ? null : '/onboarding/test';
      }

      // login -> home (bez onboardingu)
      if (inAuth || inOnboarding) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),

      // ✅ TYLKO test poziomujący w onboarding
      GoRoute(
        path: '/onboarding/test',
        builder: (_, __) => const PlacementTestScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
              GoRoute(
                path: '/chapter-list',
                builder: (_, __) => const ChapterListScreen(),
              ),
              GoRoute(
                path: '/chapter/:num',
                builder: (context, state) {
                  final num =
                      int.tryParse(state.pathParameters['num'] ?? '1') ?? 1;
                  return ChapterDetailScreen(chapterNumber: num);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/flashcards',
                builder: (_, __) => const FlashcardsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant',
                builder: (_, __) => const AiAssistantScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
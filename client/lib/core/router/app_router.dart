import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/router/router_notifier.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';
import 'package:clientpulse/features/auth/presentation/screens/login_screen.dart';
import 'package:clientpulse/features/auth/presentation/screens/register_screen.dart';
import 'package:clientpulse/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:clientpulse/features/project/presentation/screens/project_detail_screen.dart';
import 'package:clientpulse/features/project/presentation/screens/create_edit_project_screen.dart';
import 'package:clientpulse/features/settings/presentation/screens/settings_screen.dart';
import 'package:clientpulse/features/portal/presentation/screens/portal_screen.dart';
import 'package:clientpulse/features/updates/presentation/screens/create_update_screen.dart';

part 'app_router.g.dart';

// KEEP IN SYNC with GoRoute path definitions below.
const _publicPaths = ['/login', '/register'];

// Paths under this prefix bypass the top-level auth guard entirely.
// Token validation is handled at the route level via GoRoute.redirect.
const _portalPrefix = '/p/';

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  final notifier = ref.read(routerNotifierProvider.notifier);

  final goRouter = GoRouter(
    initialLocation: '/loading',
    refreshListenable: notifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // Portal paths bypass auth — token validation done at route level.
      if (path.startsWith(_portalPrefix)) return null;

      final authAsync = ref.read(isAuthenticatedProvider);

      // AsyncLoading mid-submit on a public auth path is expected — AuthNotifier
      // flips state during register/login. Keeping the user on /login or /register
      // lets the submit's catch run setState on the live State (otherwise mounted
      // is false, _errorMessage never updates, banner never renders). Only safe
      // when the user is NOT yet authenticated; an authed user landing on /login
      // mid-AsyncLoading must still bounce to /dashboard via the normal redirect.
      if (authAsync.isLoading) {
        final lastValue = authAsync.valueOrNull;
        final wasUnauthenticated = lastValue == null || lastValue == false;
        if (wasUnauthenticated && _publicPaths.contains(path)) return null;
        return path == '/loading' ? null : '/loading';
      }

      // hasError fires only when isAuthenticatedProvider's build() failed (auth
      // service init crash) — AuthNotifier's login/register catch resets to
      // AsyncData(null), it does not produce AsyncError. Holding on /loading
      // surfaces the failure rather than booting the user into a broken UI.
      if (authAsync.hasError) {
        return path == '/loading' ? null : '/loading';
      }

      final isAuthenticated = authAsync.requireValue;

      // Once resolved, redirect away from loading screen.
      // Direct navigation to /loading (e.g. bookmarked URL) is also handled here.
      if (path == '/loading') {
        return isAuthenticated ? '/dashboard' : '/login';
      }

      final isPublic = _publicPaths.contains(path);

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) return '/dashboard';
      return null;
    },
    routes: [
      // Shown while isAuthenticatedProvider is still resolving.
      GoRoute(
        path: '/loading',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (_, state) =>
            LoginScreen(prefillEmail: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
          path: RouteNames.dashboard,
          name: RouteNames.dashboard,
          builder: (_, __) => const DashboardScreen(),
          routes: [
            GoRoute(
              path: RouteNames.createProject,
              name: RouteNames.createProject,
              builder: (_, state) => CreateEditProjectScreen(
                cameFromInApp: state.extra == true,
              ),
            ),
            GoRoute(
              path: RouteNames.projectDetail,
              name: RouteNames.projectDetail,
              builder: (_, state) => ProjectDetailScreen(
                projectId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: RouteNames.editProject,
                  name: RouteNames.editProject,
                  builder: (_, state) => CreateEditProjectScreen(
                    projectId: state.pathParameters['id'],
                    cameFromInApp: state.extra == true,
                  ),
                ),
                GoRoute(
                  path: 'updates/new',
                  name: RouteNames.createUpdate,
                  builder: (_, state) => CreateUpdateScreen(
                    projectId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
      // /projects/new must be listed BEFORE /projects/:id to prevent
      // GoRouter from matching "new" as an :id path parameter.

      // GoRoute(
      //   path: '/projects/:id/edit',
      //   name: RouteNames.editProject,
      //   builder: (_, state) => CreateEditProjectScreen(
      //     projectId: state.pathParameters['id'],
      //   ),
      // ),
      // GoRoute(
      //   path: '/projects/:id/updates/new',
      //   name: RouteNames.createUpdate,
      //   builder: (_, state) => CreateUpdateScreen(
      //     projectId: state.pathParameters['id']!,
      //   ),
      // ),

      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/p/:token',
        name: RouteNames.portal,
        redirect: (_, state) {
          // GoRouter decodes path params — catches whitespace-only tokens
          // from malformed email links before they reach PortalScreen.
          final token = (state.pathParameters['token'] ?? '').trim();
          return token.isNotEmpty ? null : '/login';
        },
        builder: (_, state) => PortalScreen(
          token: state.pathParameters['token']!,
        ),
      ),
    ],
    errorBuilder: (context, __) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page not found'),
            TextButton(
              onPressed: () => context.goNamed(RouteNames.dashboard),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );

  ref.onDispose(goRouter.dispose);
  return goRouter;
}

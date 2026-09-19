// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/app/router/app_branch_routes.dart';
import 'package:khulla/app/router/route_access.dart';
import 'package:khulla/app/shell/app_shell.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/router/go_router_refresh_stream.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_state.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/onboarding_page.dart';
import 'package:khulla/features/staff_auth/presentation/recover_password/cubit/recover_password_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/recover_password/recover_password_page.dart';
import 'package:khulla/features/staff_auth/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/sign_in/sign_in_page.dart';

/// Owns the single [GoRouter] instance.
///
/// One [StatefulShellRoute] with one branch per shell destination, in the
/// order `shellDestinations` declares them, plus the manual after them all —
/// it opens from the account menu rather than the rail, so the rail never
/// targets its index. The indexed-stack form keeps
/// every branch alive — a section holds its scroll position and navigation
/// stack while the user is away in another — and swaps between them with no
/// transition, which is what a desk tool wants.
///
/// Each branch is a small tree rather than a single page: a list at the
/// branch root, records and editors nested under it. Nesting is what keeps
/// the shell's rail on screen while a librarian moves between records, and
/// what makes the back control on a detail page mean "up to the list". The
/// trees themselves live in app_branch_routes — this file is composition
/// (the router, the out-of-shell routes, the redirect) only.
///
/// Route paths are never written here as strings — [Routes] owns the
/// segments, so a rename is one edit and every caller moves with it.
///
/// Two routes sit outside the shell — onboarding and sign-in — and
/// [_redirect] is what decides when the operator is on one of them. It reads
/// [AuthCubit], and `refreshListenable` re-runs it whenever that cubit emits,
/// so signing in or out moves the app on its own with no `context.go` at the
/// call site.
@lazySingleton
class AppRouter {
  AppRouter(this._config, this._auth) {
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: Routes.dashboard,
      refreshListenable: GoRouterRefreshStream(_auth.stream),
      redirect: _redirect,
      routes: [
        GoRoute(
          path: Routes.onboarding,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, _) => BlocProvider<OnboardingCubit>(
            create: (_) => getIt<OnboardingCubit>(),
            child: const OnboardingPage(),
          ),
        ),
        GoRoute(
          path: Routes.signIn,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, _) => BlocProvider<SignInCubit>(
            create: (_) {
              final cubit = getIt<SignInCubit>();
              unawaited(cubit.loadRecoveryAvailability());
              return cubit;
            },
            child: const SignInPage(),
          ),
        ),
        GoRoute(
          path: Routes.recoverPassword,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, _) => BlocProvider<RecoverPasswordCubit>(
            create: (_) => getIt<RecoverPasswordCubit>(),
            child: const RecoverPasswordPage(),
          ),
        ),
        GoRoute(
          path: Routes.root,
          redirect: (_, _) => Routes.dashboard,
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            dashboardBranch(),
            catalogBranch(),
            circulationBranch(),
            membersBranch(),
            reportsBranch(),
            usersBranch(),
            settingsBranch(
              auth: _auth,
              includeDesignGallery: !_config.isProduction,
            ),
            guideBranch(),
          ],
        ),
      ],
    );
  }

  final AppConfig _config;
  final AuthCubit _auth;
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  /// The configured router, handed to `MaterialApp.router`.
  late final GoRouter router;

  /// Sends the operator to the one screen their session allows.
  ///
  /// `bootstrap` resolves the session before the first frame, so
  /// [AuthStatus.unknown] here means the catalogue could not be read at all.
  /// It redirects nowhere in that case: guessing "needs setup" would offer to
  /// create a second administrator over the top of a real library, and the
  /// startup failure screen is already what the operator is looking at.
  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    return switch (_auth.state.status) {
      AuthStatus.unknown => null,
      AuthStatus.needsSetup =>
        location == Routes.onboarding ? null : Routes.onboarding,
      AuthStatus.signedOut =>
        location == Routes.signIn || location == Routes.recoverPassword
            ? null
            : Routes.signIn,
      AuthStatus.signedIn =>
        Routes.isAuthLocation(location)
            ? Routes.dashboard
            : _redirectForPermission(location),
    };
  }

  /// Sends a signed-in operator away from a section their role cannot open.
  ///
  /// The shell already hides what a role cannot reach, so this catches the
  /// quiet ways in that the rail cannot: a stale link, a typed URL, a
  /// bookmark, or a role that changed under a window left open. Every one of
  /// them deserves a real answer rather than a section that renders and then
  /// writes something the role was never meant to write.
  ///
  /// [accessFor] holds the whole map, and the dashboard is the floor every
  /// role keeps, so the redirect can never loop.
  String? _redirectForPermission(String location) {
    final access = accessFor(location);
    if (access == null || access.allows(_auth.state.role)) return null;
    return Routes.dashboard;
  }
}

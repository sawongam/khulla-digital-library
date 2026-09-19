// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/app/router/route_access.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/catalog/copy/presentation/copy_list_page.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_cubit.dart';
import 'package:khulla/features/catalog/label/presentation/cubit/label_cubit.dart';
import 'package:khulla/features/catalog/label/presentation/label_print_page.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_cubit.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_detail_cubit.dart';
import 'package:khulla/features/catalog/title/presentation/title_detail_page.dart';
import 'package:khulla/features/catalog/title/presentation/title_list_page.dart';
import 'package:khulla/features/circulation/check_out/presentation/check_out_page.dart';
import 'package:khulla/features/circulation/check_out/presentation/cubit/check_out_cubit.dart';
import 'package:khulla/features/circulation/circulation/presentation/circulation_page.dart';
import 'package:khulla/features/circulation/circulation/presentation/cubit/loan_list_cubit.dart';
import 'package:khulla/features/circulation/fine/presentation/cubit/fine_list_cubit.dart';
import 'package:khulla/features/circulation/fine/presentation/fine_list_page.dart';
import 'package:khulla/features/circulation/reservation/presentation/cubit/reservation_list_cubit.dart';
import 'package:khulla/features/circulation/reservation/presentation/reservation_list_page.dart';
import 'package:khulla/features/circulation/return_copy/presentation/cubit/return_cubit.dart';
import 'package:khulla/features/circulation/return_copy/presentation/return_page.dart';
import 'package:khulla/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:khulla/features/dashboard/presentation/dashboard_page.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/features/guide/presentation/guide_article_page.dart';
import 'package:khulla/features/guide/presentation/guide_page.dart';
import 'package:khulla/features/members/presentation/cubit/member_cubit.dart';
import 'package:khulla/features/members/presentation/cubit/member_detail_cubit.dart';
import 'package:khulla/features/members/presentation/pages/member_detail_page.dart';
import 'package:khulla/features/members/presentation/pages/member_list_page.dart';
import 'package:khulla/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:khulla/features/reports/presentation/reports_page.dart';
import 'package:khulla/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/loan_rules_cubit.dart';
import 'package:khulla/features/settings/presentation/pages/appearance_page.dart';
import 'package:khulla/features/settings/presentation/pages/backup_page.dart';
import 'package:khulla/features/settings/presentation/pages/library_profile_page.dart';
import 'package:khulla/features/settings/presentation/pages/loan_rules_page.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_cubit.dart';
import 'package:khulla/features/users/presentation/pages/role_list_page.dart';
import 'package:khulla/features/users/presentation/pages/user_list_page.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One [StatefulShellBranch] per shell destination, in the order
/// `shellDestinations` declares them — plus the manual, which has no rail
/// entry and so sits after them all. Its index is never targeted by the rail;
/// it is reached through `context.go`, which activates whichever branch holds
/// the matched route.
///
/// Extracted from AppRouter so the router file stays composition (the
/// single `GoRouter`, the out-of-shell routes, the redirect) while each
/// branch keeps its own page tree with its `BlocProvider` wiring — providers
/// are created here, never with `getIt` in a widget.
StatefulShellBranch dashboardBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, _) => BlocProvider<DashboardCubit>(
        create: (_) {
          final cubit = getIt<DashboardCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const DashboardPage(),
      ),
    ),
  ],
);

StatefulShellBranch catalogBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.catalog,
      redirect: (_, state) =>
          state.uri.path == Routes.catalog ? Routes.catalogTitles : null,
      routes: [
        GoRoute(
          path: Routes.titlesSegment,
          builder: (context, _) => BlocProvider<TitleCubit>(
            create: (_) {
              final cubit = getIt<TitleCubit>();
              unawaited(cubit.loadTitles());
              return cubit;
            },
            child: const TitleListPage(),
          ),
          routes: [
            GoRoute(
              path: Routes.idSegment,
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return BlocProvider<TitleDetailCubit>(
                  create: (_) {
                    final cubit = getIt<TitleDetailCubit>();
                    unawaited(cubit.loadTitle(id));
                    return cubit;
                  },
                  child: TitleDetailPage(titleId: id),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.copiesSegment,
          builder: (context, _) => BlocProvider<CopyCubit>(
            create: (_) {
              final cubit = getIt<CopyCubit>();
              unawaited(cubit.loadCopies());
              return cubit;
            },
            child: const CopyListPage(),
          ),
        ),
        GoRoute(
          path: Routes.labelsSegment,
          builder: (context, _) => BlocProvider<LabelCubit>(
            create: (_) {
              final cubit = getIt<LabelCubit>();
              unawaited(cubit.loadLabelDesk());
              return cubit;
            },
            child: const LabelPrintPage(),
          ),
        ),
      ],
    ),
  ],
);

StatefulShellBranch circulationBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.circulation,
      redirect: (_, state) =>
          state.uri.path == Routes.circulation ? Routes.circulationLoans : null,
      routes: [
        GoRoute(
          path: Routes.loansSegment,
          builder: (context, _) => BlocProvider<LoanListCubit>(
            create: (_) {
              final cubit = getIt<LoanListCubit>();
              unawaited(cubit.loadOpenLoans());
              return cubit;
            },
            child: const CirculationPage(),
          ),
        ),
        GoRoute(
          path: Routes.checkOutSegment,
          builder: (context, state) {
            final card = state.uri.queryParameters['card'];
            return BlocProvider<CheckOutCubit>(
              create: (_) {
                final cubit = getIt<CheckOutCubit>();
                if (card != null && card.isNotEmpty) {
                  unawaited(cubit.lookupMember(card));
                }
                return cubit;
              },
              child: const CheckOutPage(),
            );
          },
        ),
        GoRoute(
          path: Routes.returnsSegment,
          builder: (context, _) => BlocProvider<ReturnCubit>(
            create: (_) => getIt<ReturnCubit>(),
            child: const ReturnPage(),
          ),
        ),
        GoRoute(
          path: Routes.reservationsSegment,
          builder: (context, _) => BlocProvider<ReservationListCubit>(
            create: (_) {
              final cubit = getIt<ReservationListCubit>();
              unawaited(cubit.loadReservations());
              return cubit;
            },
            child: const ReservationListPage(),
          ),
        ),
        GoRoute(
          path: Routes.finesSegment,
          builder: (context, _) => BlocProvider<FineListCubit>(
            create: (_) {
              final cubit = getIt<FineListCubit>();
              unawaited(cubit.loadFines());
              return cubit;
            },
            child: const FineListPage(),
          ),
        ),
      ],
    ),
  ],
);

StatefulShellBranch membersBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.members,
      builder: (context, _) => BlocProvider<MemberCubit>(
        create: (_) {
          final cubit = getIt<MemberCubit>();
          unawaited(cubit.loadMembers());
          return cubit;
        },
        child: const MemberListPage(),
      ),
      routes: [
        GoRoute(
          path: Routes.idSegment,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return BlocProvider<MemberDetailCubit>(
              create: (_) {
                final cubit = getIt<MemberDetailCubit>();
                unawaited(cubit.loadMember(id));
                return cubit;
              },
              child: MemberDetailPage(memberId: id),
            );
          },
        ),
      ],
    ),
  ],
);

StatefulShellBranch reportsBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.reports,
      builder: (context, _) => BlocProvider<ReportsCubit>(
        create: (_) {
          final cubit = getIt<ReportsCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const ReportsPage(),
      ),
    ),
  ],
);

StatefulShellBranch usersBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.users,
      builder: (context, _) => BlocProvider<StaffListCubit>(
        create: (_) {
          final cubit = getIt<StaffListCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const UserListPage(),
      ),
      routes: [
        GoRoute(
          path: Routes.rolesSegment,
          builder: (context, _) => BlocProvider<StaffListCubit>(
            create: (_) {
              final cubit = getIt<StaffListCubit>();
              unawaited(cubit.load());
              return cubit;
            },
            child: const RoleListPage(),
          ),
        ),
      ],
    ),
  ],
);

/// The manual. Last, to match the rail: it sits under the work rather than
/// above it.
///
/// Neither page holds a cubit — the guide is built from localizations on
/// every build, so both builders hand over plain pages. An unknown `:topic`
/// segment is not a routing failure: [guideTopicFromSlug] answers null and
/// the article page renders its own not-found state.
StatefulShellBranch guideBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.guide,
      builder: (context, _) => const GuidePage(),
      routes: [
        GoRoute(
          path: Routes.guideTopicSegment,
          builder: (context, state) {
            final topic = guideTopicFromSlug(
              state.pathParameters['topic'],
            );
            return GuideArticlePage(
              topic: topic,
              anchor: state.uri.queryParameters['section'],
            );
          },
        ),
      ],
    ),
  ],
);

/// The settings tree. [auth] is the live cubit, not a snapshot: where the
/// section opens depends on the role, and the redirect reads it at redirect
/// time because a role can change under a window left open. The component
/// gallery is a development surface — [includeDesignGallery] is false in the
/// release build, so there is no way to reach it by typing the URL either.
StatefulShellBranch settingsBranch({
  required AuthCubit auth,
  required bool includeDesignGallery,
}) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.settings,
      // Where the section opens depends on the role: sending an
      // account without the settings permission to the library
      // profile would bounce it straight back out, which reads
      // as the rail row doing nothing at all.
      redirect: (_, state) => state.uri.path == Routes.settings
          ? settingsLandingFor(auth.state.role)
          : null,
      routes: [
        GoRoute(
          path: Routes.librarySegment,
          builder: (context, _) => BlocProvider<LibraryProfileCubit>(
            create: (_) {
              final cubit = getIt<LibraryProfileCubit>();
              unawaited(cubit.loadProfile());
              return cubit;
            },
            child: const LibraryProfilePage(),
          ),
        ),
        GoRoute(
          path: Routes.loanRulesSegment,
          builder: (context, _) => BlocProvider<LoanRulesCubit>(
            create: (_) {
              final cubit = getIt<LoanRulesCubit>();
              unawaited(cubit.loadRules());
              return cubit;
            },
            child: const LoanRulesPage(),
          ),
        ),
        GoRoute(
          path: Routes.appearanceSegment,
          builder: (context, _) => const AppearancePage(),
        ),
        GoRoute(
          path: Routes.backupSegment,
          builder: (context, _) => BlocProvider<BackupCubit>(
            create: (_) {
              final cubit = getIt<BackupCubit>();
              unawaited(cubit.load());
              return cubit;
            },
            child: const BackupPage(),
          ),
        ),
        // The component gallery is a development surface: the
        // release build never declares the route, so there is no
        // way to reach it by typing the URL either.
        if (includeDesignGallery)
          GoRoute(
            path: Routes.designSystemSegment,
            builder: (context, _) => const AppDesignGallery(),
          ),
      ],
    ),
  ],
);

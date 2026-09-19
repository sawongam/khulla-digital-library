// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/app/shell/widgets/shell_brand_mark.dart';
import 'package:khulla/app/shell/widgets/shell_destinations.dart';
import 'package:khulla/app/shell/widgets/shell_more_sheet.dart';
import 'package:khulla/app/shell/widgets/shell_page_actions.dart';
import 'package:khulla/app/shell/widgets/shell_page_title.dart';
import 'package:khulla/app/shell/widgets/shell_rail_footer.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The app's only shell, adapting its navigation to the window it is given.
///
/// Khulla runs on a maximised desktop window and in a phone browser tab from
/// the same build, so navigation is chosen at layout time rather than at
/// compile time: a rail from [FormFactor.medium] up, a bottom bar below it.
/// Both are driven by the same [shellDestinations] list, so resizing across
/// the breakpoint never reorders or drops a section.
///
/// The shell owns the top bar, and the top bar sits *outside* the page's
/// scroll view. That is the whole reason it lives here: the page title and
/// the section's actions have to stay put while a catalogue of ten thousand
/// titles scrolls, and no arrangement inside a page achieves that as simply.
///
/// The chrome is split by *scope*, not by convenience. The brand header sits
/// above the rail in the left column; the top bar tops the page column beside
/// it. Theme lives under Settings → Appearance.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  /// Branch state owned by the router. Each destination is one branch, so a
  /// section keeps its scroll position and navigation stack while the user is
  /// away in another.
  final StatefulNavigationShell navigationShell;

  /// How many sections the compact bottom bar shows before *More*.
  static const int _compactSlots = 4;

  void _goBranch(BuildContext context, int index, UserRole role) {
    final destinations = shellDestinations(context.l10n, role);
    final target = index < destinations.length
        ? destinations[index].route
        : null;
    navigationShell.goBranch(
      index,
      // Tapping the active destination returns to the top of that branch, the
      // behaviour every tabbed app has trained people to expect. The members
      // section always re-enters at the register: a profile left open on its
      // stack would otherwise greet the next visit instead of the list.
      initialLocation:
          index == navigationShell.currentIndex || target == Routes.members,
    );
  }

  void _goRoute(BuildContext context, String route) => context.go(route);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formFactor = context.formFactor;
    final auth = context.watch<AuthCubit>().state;
    final role = auth.staff?.role ?? UserRole.readOnly;
    final destinations = shellDestinations(l10n, role);
    // Every branch stays in `destinations` at its router index - dropping an
    // entry here instead would desync the rail's `onDestinationSelected`
    // from `navigationShell.goBranch`. `visibleIndices` is the list of
    // original indices a role may actually see; the rail below maps through
    // it in both directions instead of indexing `destinations` directly.
    final visibleIndices = [
      for (var i = 0; i < destinations.length; i++)
        if (destinations[i].permission == null ||
            auth.canView(destinations[i].permission!))
          i,
    ];
    final visibleDestinations = [
      for (final i in visibleIndices) destinations[i],
    ];
    final location = GoRouterState.of(context).uri.path;

    final page = shellPageTitle(
      context,
      location,
      l10n,
      role: role,
      onNavigate: (route) => _goRoute(context, route),
    );

    final actions = shellPageActions(context, location, l10n);
    final compact = !formFactor.usesNavigationRail;

    final topBar = AppTopBar(
      title: page.title,
      // A phone drops the trail. It is one row of chrome saying what the
      // bottom bar's highlighted tab already says, and the title below it
      // repeats its last crumb verbatim.
      breadcrumbs: page.crumbs.isEmpty || compact
          ? null
          : AppBreadcrumbs(crumbs: page.crumbs),
      actions: actions,
      wrapSafeArea: compact,
      // No `leading`. A phone used to get a menu button here, but the bottom
      // bar's *More* slot opens the same sheet, and two ways to reach it is
      // one too many on the width that can least afford the control.
    );

    if (compact) {
      // A primary destination can be hidden like any other - a role that
      // cannot open the catalogue does not get a catalogue tab - so the bar's
      // slots are numbered over what this role actually sees. `compactSlots`
      // maps a slot back to its branch index; anything past the four slots,
      // and any section that is not showing, lives behind *More*.
      final compactSlots = [
        for (final i in visibleIndices)
          if (destinations[i].primary) i,
      ].take(_compactSlots).toList();
      final compactDestinations = [
        for (final i in compactSlots) destinations[i],
      ];
      final slot = compactSlots.indexOf(navigationShell.currentIndex);

      // A section that is already named by the highlighted tab, with nothing
      // to offer beyond its name, gets no bar at all - the band of chrome was
      // pure repetition, and the dashboard starts a phone screen higher
      // without it. A section reached through *More* keeps its bar whatever
      // else is on it: the bottom bar says *More*, not where you are.
      final showTopBar =
          actions.isNotEmpty || page.crumbs.isNotEmpty || slot < 0;

      return Scaffold(
        body: Column(
          children: [
            if (showTopBar)
              topBar
            else
              // The bar consumed the status-bar inset for the page. Without
              // it the page has to, and the inset is handed to whatever the
              // page draws first rather than being paid twice.
              SizedBox(height: MediaQuery.paddingOf(context).top),
            // The page's own `AppPageBody` would otherwise re-inset for a
            // status bar that the bar above has already cleared - the gap
            // between the header and the content.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: navigationShell,
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppNavBar(
          // The current section may have no slot of its own - a role reading
          // reports is inside *More* - and the bar then highlights *More*.
          selectedIndex: slot >= 0 ? slot : compactSlots.length,
          onDestinationSelected: (selected) {
            if (selected < compactSlots.length) {
              _goBranch(context, compactSlots[selected], role);
              return;
            }
            unawaited(
              showShellMoreSheet(
                context,
                destinations: visibleDestinations,
                current: location,
              ),
            );
          },
          destinations: [
            for (final destination in compactDestinations)
              AppNavDestination(
                icon: AppIcon(destination.icon),
                label: destination.label,
              ),
            AppNavDestination(
              icon: const AppIcon(AppIcons.gridView),
              label: l10n.navMore,
            ),
          ],
        ),
      );
    }

    final extended = formFactor.usesExtendedRail;
    final railWidth = extended
        ? AppNavRail.extendedWidth
        : AppNavRail.collapsedWidth;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: railWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShellBrandHeader(extended: extended),
                  Expanded(
                    child: AppNavRail(
                      selectedIndex: visibleIndices.indexOf(
                        navigationShell.currentIndex,
                      ),
                      onDestinationSelected: (i) =>
                          _goBranch(context, visibleIndices[i], role),
                      extended: extended,
                      wrapSafeArea: false,
                      footer: ShellRailFooter(extended: extended),
                      destinations: [
                        for (final destination in visibleDestinations)
                          AppNavDestination(
                            icon: AppIcon(destination.icon),
                            label: destination.label,
                            expandedByDefault: destination.expandedByDefault,
                            children: [
                              for (final child in destination.children)
                                AppNavChild(
                                  label: child.label,
                                  selected: isSelectedShellRoute(
                                    location,
                                    child.route,
                                    [
                                      for (final sibling
                                          in destination.children)
                                        sibling.route,
                                    ],
                                  ),
                                  onSelected: () =>
                                      _goRoute(context, child.route),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  topBar,
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

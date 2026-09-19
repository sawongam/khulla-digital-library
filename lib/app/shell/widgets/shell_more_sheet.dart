// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/app/shell/help/about_dialog.dart';
import 'package:khulla/app/shell/widgets/shell_destinations.dart';
import 'package:khulla/app/shell/widgets/shell_version_label.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/features/users/presentation/widgets/staff_profile_dialog.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Opens the sheet listing every section, for a window too narrow to show
/// them all in the bottom bar.
///
/// A bottom bar holds four destinations before the labels start eating each
/// other; this app has eight. Rather than dropping the four that did not fit,
/// the bar keeps the daily ones and this sheet carries the whole list -
/// including the sub-sections, which the bar could never have shown at all.
///
/// The sheet reads as a plain menu: quiet rows, one icon weight, dividers
/// only where one group ends and the next begins. The active route takes the
/// brand wash so the sheet says where you are, not just where you can go.
Future<void> showShellMoreSheet(
  BuildContext context, {
  required List<ShellDestination> destinations,
  required String current,
}) => AppBottomSheet.show<void>(
  context: context,
  title: context.l10n.shellMoreTitle,
  // The whole navigation tree, not a short picker: it earns more of the
  // screen than the default sheet does.
  heightFactor: 0.85,
  builder: (sheetContext) => _MoreList(
    destinations: destinations,
    current: current,
  ),
);

class _MoreList extends StatelessWidget {
  const _MoreList({required this.destinations, required this.current});

  final List<ShellDestination> destinations;
  final String current;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final l10n = context.l10n;
    final staff = context.watch<AuthCubit>().state.staff;

    // The sheet chrome already scrolls a fixed-height body, so this is a
    // plain column of menu rows.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The rail carries the account chip in its footer; a phone has no
        // rail, so who is signed in lives here instead - otherwise a compact
        // window can never reach the profile.
        if (staff != null) ...[
          _SheetTap(
            onTap: () => unawaited(StaffProfileDialog.show(context)),
            child: _AccountRow(
              name: staff.name,
              role: staff.role.label(l10n),
              initials: staff.initials,
            ),
          ),
          SizedBox(height: spacing.xs),
          Divider(height: 1, color: context.appColors.hairline),
          SizedBox(height: spacing.xs),
        ],
        for (final destination in destinations) ...[
          _SheetTap(
            onTap: () => context.go(destination.route),
            child: _MenuRow(
              label: destination.label,
              icon: destination.icon,
              selected: isSelectedShellRoute(
                current,
                destination.route,
                [
                  destination.route,
                  for (final child in destination.children) child.route,
                ],
              ),
            ),
          ),
          for (final child in destination.children)
            _SheetTap(
              onTap: () => context.go(child.route),
              child: _MenuRow(
                label: child.label,
                icon: AppIcons.subEntry,
                indented: true,
                selected: isSelectedShellRoute(current, child.route, [
                  for (final sibling in destination.children) sibling.route,
                ]),
              ),
            ),
        ],
        SizedBox(height: spacing.xs),
        Divider(height: 1, color: context.appColors.hairline),
        SizedBox(height: spacing.xs),
        // Phones never see the rail footer, and the account menu that carries
        // the guide and the about panel on a window lives in it - so both
        // hang here instead, below the sections and above the version line.
        _SheetTap(
          onTap: () => context.go(Routes.guide),
          child: _MenuRow(
            label: l10n.shellGuide,
            icon: AppIcons.openBook,
            selected: Routes.isUnder(current, Routes.guide),
          ),
        ),
        _SheetTap(
          onTap: () => unawaited(HelpAboutDialog.show(context)),
          child: _MenuRow(label: l10n.shellAbout, icon: AppIcons.info),
        ),
        if (staff != null)
          _SheetTap(
            onTap: () => unawaited(context.read<AuthCubit>().signOut()),
            child: _MenuRow(
              label: l10n.shellSignOut,
              icon: AppIcons.signOut,
              destructive: true,
            ),
          ),
        SizedBox(height: spacing.sm),
        const ShellVersionLabel(),
      ],
    );
  }
}

/// Dismisses the sheet, then runs the row's navigation.
class _SheetTap extends StatelessWidget {
  const _SheetTap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.appRadius.control);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        borderRadius: radius,
        child: child,
      ),
    );
  }
}

/// Who is signed in: avatar, name and role. Opens the profile.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.role,
    required this.initials,
  });

  final String name;
  final String role;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      child: Row(
        children: [
          AppAvatar(initials: initials),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.xs),
          AppIcon(
            AppIcons.chevronRight,
            size: context.appMetrics.icon,
            color: colors.ink400,
          ),
        ],
      ),
    );
  }
}

/// One menu row: a quiet glyph, a label, and the brand wash when active -
/// nothing else. Sub-sections indent so they read under their parent.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.icon,
    this.selected = false,
    this.destructive = false,
    this.indented = false,
  });

  final String label;
  final AppIconSpec icon;
  final bool selected;
  final bool destructive;
  final bool indented;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final foreground = destructive
        ? scheme.error
        : selected
        ? scheme.primary
        : colors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: selected ? colors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(context.appRadius.control),
      ),
      padding: EdgeInsets.fromLTRB(
        indented ? spacing.sm + 20 + spacing.sm : spacing.sm,
        spacing.sm,
        spacing.sm,
        spacing.sm,
      ),
      child: Row(
        children: [
          AppIcon(
            icon,
            size: indented
                ? context.appMetrics.iconInButton
                : context.appMetrics.icon,
            color: destructive
                ? scheme.error
                : selected
                ? scheme.primary
                : colors.ink400,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

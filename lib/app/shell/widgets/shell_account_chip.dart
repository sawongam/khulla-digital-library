// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/app/shell/help/about_dialog.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/features/users/presentation/widgets/staff_profile_dialog.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Who is signed in, at the foot of the rail.
///
/// It shows the name *and* the role because a shared desk machine is the
/// normal case in a library: the person about to waive a fine needs to see,
/// without opening a menu, whether they are signed in as themselves or as
/// whoever worked the morning shift.
///
/// The menu opens above the full footer row, not from the avatar alone — the
/// whole row is the tap target and the panel anchors to its width.
///
/// It renders nothing when nobody is signed in. That is unreachable in
/// practice — the shell is behind the router's redirect — but a signed-out
/// frame can still be built for one pass while the redirect settles.
class ShellAccountChip extends StatelessWidget {
  const ShellAccountChip({this.compact = false, super.key});

  /// Drops the name and role, leaving the avatar alone.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final staff = context.watch<AuthCubit>().state.staff;

    if (staff == null) return const SizedBox.shrink();

    // The cursor sits on the trigger itself, inside the button:
    // PopupMenuButton wraps its child in an InkWell whose default cursor
    // (adaptiveClickable) resolves to the basic arrow on desktop, and the
    // innermost MouseRegion wins — an outer one would never take effect.
    return PopupMenuButton<int>(
      tooltip: l10n.shellAccountMenu,
      position: PopupMenuPosition.over,
      constraints: const BoxConstraints(minWidth: 220),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              unawaited(StaffProfileDialog.show(context));
            }
          }),
          child: _MenuRow(
            icon: AppIcons.person,
            label: l10n.shellProfile,
          ),
        ),
        PopupMenuItem<int>(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => context.go(Routes.settingsAppearance),
          child: _MenuRow(
            icon: AppIcons.settings,
            label: l10n.navSettingsAppearance,
          ),
        ),
        PopupMenuItem<int>(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => context.go(Routes.guide),
          child: _MenuRow(
            icon: AppIcons.openBook,
            label: l10n.shellGuide,
          ),
        ),
        PopupMenuItem<int>(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              unawaited(HelpAboutDialog.show(context));
            }
          }),
          child: _MenuRow(
            icon: AppIcons.info,
            label: l10n.shellAbout,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          mouseCursor: SystemMouseCursors.click,
          // No confirmation: signing out costs nothing to undo, and the
          // catalogue is untouched — the next screen is sign-in.
          onTap: () => unawaited(context.read<AuthCubit>().signOut()),
          child: _MenuRow(
            icon: AppIcons.signOut,
            label: l10n.shellSignOut,
            destructive: true,
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? spacing.xxs : spacing.sm,
              vertical: spacing.xxs,
            ),
            child: compact
                ? Center(child: AppAvatar(initials: staff.initials, size: 34))
                : Row(
                    children: [
                      AppAvatar(initials: staff.initials, size: 34),
                      SizedBox(width: spacing.xs),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              staff.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textHigh,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              staff.role.label(l10n),
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
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: colors.hairline.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(
                            context.appRadius.pill,
                          ),
                        ),
                        child: Center(
                          child: AppIcon(
                            AppIcons.chevronDown,
                            size: 14,
                            color: colors.ink400,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final AppIconSpec icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.colorScheme.error
        : context.colorScheme.onSurface;

    return Row(
      children: [
        AppIcon(icon, size: 18, color: color),
        SizedBox(width: context.appSpacing.xs),
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

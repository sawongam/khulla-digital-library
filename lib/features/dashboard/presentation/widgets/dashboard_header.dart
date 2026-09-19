// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The board's controls: which period its figures cover, and the two actions
/// a shift starts with.
///
/// No greeting and no page title. The shell's top bar already names the page
/// and the account chip already says who the till is open as, so a headline
/// here would be a second title that scrolls away — the exact thing putting
/// the bar in the shell was meant to prevent. What is left is a control
/// strip: the period switch governs every figure below it, so it belongs
/// once at the top rather than on each card.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.period,
    required this.onPeriodChanged,
    super.key,
  });

  /// Which period the board's figures cover.
  final DashboardPeriod period;

  /// Called when the operator picks another period.
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final stacked = context.formFactor.isCompact;
    // The board is the one section every role opens, so its two shortcuts
    // are the desks a role may not be able to work. Without them the header
    // is the period control alone.
    final canWorkTheDesk = context.canManage(StaffPermission.circulation);

    final periods = AppSegmentedControl<DashboardPeriod>(
      value: period,
      // Stacked, the control owns the full width, and three segments sharing
      // it equally is the only arrangement where the track does not end in
      // dead grey space beside *This month*.
      expand: stacked,
      items: DashboardPeriod.values,
      itemLabel: (item) => switch (item) {
        DashboardPeriod.today => l10n.commonToday,
        DashboardPeriod.week => l10n.commonThisWeek,
        DashboardPeriod.month => l10n.commonThisMonth,
      },
      onChanged: onPeriodChanged,
    );

    final checkOut = AppButton(
      size: AppButtonSize.medium,
      icon: AppIcons.scan,
      expand: stacked,
      onPressed: () => context.go(Routes.circulationCheckOut),
      child: Text(l10n.dashboardCheckOut),
    );

    final returnCopy = AppButton(
      size: AppButtonSize.medium,
      variant: AppButtonVariant.outline,
      icon: AppIcons.checkIn,
      expand: stacked,
      onPressed: () => context.go(Routes.circulationReturn),
      child: Text(l10n.dashboardReturnCopy),
    );

    if (stacked) {
      // The two desk shortcuts share one row rather than taking a band each.
      // They are a pair — the same copy goes out and comes back — and two
      // full-width buttons stacked read as two unrelated decisions while
      // costing the board a card's worth of height.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          periods,
          if (canWorkTheDesk) ...[
            SizedBox(height: spacing.xs),
            Row(
              children: [
                Expanded(child: checkOut),
                SizedBox(width: spacing.xs),
                Expanded(child: returnCopy),
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        periods,
        const Spacer(),
        if (canWorkTheDesk) ...[
          returnCopy,
          SizedBox(width: spacing.xs),
          checkOut,
        ],
      ],
    );
  }
}

/// The window of time the board's figures cover.
enum DashboardPeriod { today, week, month }

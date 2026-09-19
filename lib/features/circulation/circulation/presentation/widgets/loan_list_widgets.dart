// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/circulation/shared/domain/loan_status.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The desk's headline figures: out, due today, late, and waiting holds.
///
/// Tapping a counter selects the same rows its filter chip would - the tile
/// and the chip are two doors into one query.
class LoanListStats extends StatelessWidget {
  const LoanListStats({
    required this.onLoanCount,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.holdsCount,
    required this.onAllTap,
    required this.onDueTodayTap,
    required this.onOverdueTap,
    required this.onHoldsTap,
    super.key,
  });

  final int onLoanCount;
  final int dueTodayCount;
  final int overdueCount;
  final int holdsCount;
  final VoidCallback onAllTap;
  final VoidCallback onDueTodayTap;
  final VoidCallback onOverdueTap;
  final VoidCallback onHoldsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppStatStrip(
      tiles: [
        AppStatTile(
          label: l10n.circulationStatOnLoan,
          value: '$onLoanCount',
          icon: AppIcons.transfer,
          tone: AppStatusTone.brand,
          onTap: onAllTap,
        ),
        AppStatTile(
          label: l10n.circulationStatDueToday,
          value: '$dueTodayCount',
          icon: AppIcons.event,
          tone: AppStatusTone.warning,
          onTap: onDueTodayTap,
        ),
        AppStatTile(
          label: l10n.circulationStatOverdue,
          value: '$overdueCount',
          icon: AppIcons.error,
          tone: AppStatusTone.danger,
          onTap: onOverdueTap,
        ),
        AppStatTile(
          label: l10n.circulationStatHolds,
          value: '$holdsCount',
          icon: AppIcons.bookmark,
          tone: AppStatusTone.info,
          onTap: onHoldsTap,
        ),
      ],
    );
  }
}

/// Search plus the three loan-state chips.
///
/// Dumb by design: the page owns the query and wires every control back to
/// the cubit.
class LoanListToolbar extends StatelessWidget {
  const LoanListToolbar({
    required this.status,
    required this.isFiltered,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onClearFilters,
    super.key,
  });

  final LoanStatus? status;
  final bool isFiltered;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LoanStatus?> onStatusFilterChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppToolbar(
      search: AppSearchField(
        hintText: l10n.circulationSearchHint,
        clearTooltip: l10n.commonClearSearch,
        onChanged: onSearchChanged,
      ),
      filters: [
        AppFilterChip(
          label: l10n.circulationFilterOnLoan,
          icon: AppIcons.transfer,
          selected: status == LoanStatus.onLoan,
          onSelected: (selected) => onStatusFilterChanged(
            selected ? LoanStatus.onLoan : null,
          ),
        ),
        AppFilterChip(
          label: l10n.circulationFilterDueToday,
          icon: AppIcons.event,
          tone: AppStatusTone.warning,
          selected: status == LoanStatus.dueToday,
          onSelected: (selected) => onStatusFilterChanged(
            selected ? LoanStatus.dueToday : null,
          ),
        ),
        AppFilterChip(
          label: l10n.circulationFilterOverdue,
          icon: AppIcons.error,
          tone: AppStatusTone.danger,
          selected: status == LoanStatus.overdue,
          onSelected: (selected) => onStatusFilterChanged(
            selected ? LoanStatus.overdue : null,
          ),
        ),
      ],
      actions: [
        if (isFiltered)
          AppTextButton(
            onPressed: onClearFilters,
            child: Text(l10n.commonClearFilters),
          ),
      ],
    );
  }
}

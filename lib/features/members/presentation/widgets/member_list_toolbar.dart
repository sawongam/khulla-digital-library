// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member_query.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Search plus the desk's four questions of the register - who is holding
/// something, who owes something, whose card is expiring or stopped working.
///
/// Dumb by design: the page owns the query and wires every control
/// back to its cubit.
class MemberListToolbar extends StatelessWidget {
  const MemberListToolbar({
    required this.searchController,
    required this.query,
    required this.isFiltered,
    required this.onSearchChanged,
    required this.onWithLoansChanged,
    required this.onOwesFinesChanged,
    required this.onExpiringChanged,
    required this.onSuspendedChanged,
    required this.onClearFilters,
    super.key,
  });

  final TextEditingController searchController;
  final MemberQuery query;
  final bool isFiltered;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onWithLoansChanged;
  final ValueChanged<bool> onOwesFinesChanged;
  final ValueChanged<bool> onExpiringChanged;
  final ValueChanged<bool> onSuspendedChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppToolbar(
      search: AppSearchField(
        hintText: l10n.membersSearchHint,
        clearTooltip: l10n.commonClearSearch,
        controller: searchController,
        onChanged: onSearchChanged,
      ),
      filters: [
        AppFilterChip(
          label: l10n.membersFilterWithLoans,
          icon: AppIcons.transfer,
          selected: query.withLoans,
          onSelected: onWithLoansChanged,
        ),
        AppFilterChip(
          label: l10n.membersFilterOwesFines,
          icon: AppIcons.wallet,
          tone: AppStatusTone.danger,
          selected: query.owesFines,
          onSelected: onOwesFinesChanged,
        ),
        AppFilterChip(
          label: l10n.membersFilterExpiring,
          icon: AppIcons.clock,
          tone: AppStatusTone.warning,
          selected: query.expiring,
          onSelected: onExpiringChanged,
        ),
        AppFilterChip(
          label: l10n.membersFilterSuspended,
          icon: AppIcons.blocked,
          tone: AppStatusTone.danger,
          selected: query.suspended,
          onSelected: onSuspendedChanged,
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

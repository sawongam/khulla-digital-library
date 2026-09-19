// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/circulation/shared/domain/fine_status.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Search plus one chip per fine status.
///
/// Dumb by design: the page owns the query and wires every control back to
/// the cubit.
class FineListToolbar extends StatelessWidget {
  const FineListToolbar({
    required this.status,
    required this.isFiltered,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onClearFilters,
    super.key,
  });

  final FineStatus? status;
  final bool isFiltered;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<FineStatus?> onStatusFilterChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppToolbar(
      search: AppSearchField(
        hintText: l10n.finesSearchHint,
        clearTooltip: l10n.commonClearSearch,
        onChanged: onSearchChanged,
      ),
      filters: [
        for (final option in FineStatus.values)
          AppFilterChip(
            label: option.label(l10n),
            tone: option.tone,
            selected: status == option,
            onSelected: (selected) =>
                onStatusFilterChanged(selected ? option : null),
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

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:khulla/features/reports/presentation/reports_page.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/collection_header.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The board header: heading plus the period switch.
///
/// The cubit owns the period; this only renders the control.
class ReportsHeader extends StatelessWidget {
  const ReportsHeader({required this.period, super.key});

  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CollectionHeader(
      title: l10n.reportsHeading,
      subtitle: l10n.reportsSubtitle,
      trailing: AppSegmentedControl<ReportPeriod>(
        value: period,
        items: ReportPeriod.values,
        itemLabel: (item) => switch (item) {
          ReportPeriod.month => l10n.commonThisMonth,
          ReportPeriod.quarter => l10n.commonThisQuarter,
          ReportPeriod.year => l10n.commonThisYear,
        },
        onChanged: (period) =>
            context.read<ReportsCubit>().changePeriod(period),
      ),
    );
  }
}

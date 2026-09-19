// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What this return adds up to, the condition it is recorded in, and the
/// waiver the desk can apply before committing it.
///
/// The waiver is a form value, not a setting, so it is an [AppCheckboxField]
/// rather than an [AppSwitchField] - nothing has happened until *Confirm
/// return* is pressed.
class ReturnSummaryCard extends StatelessWidget {
  const ReturnSummaryCard({
    required this.copyCount,
    required this.lateCount,
    required this.finesDue,
    required this.waiveFines,
    required this.onWaiveChanged,
    required this.condition,
    required this.onConditionChanged,
    required this.onConfirm,
    super.key,
  });

  final int copyCount;
  final int lateCount;

  /// The total, already reduced by the waiver where one is applied.
  final Money finesDue;

  final bool waiveFines;
  final ValueChanged<bool> onWaiveChanged;

  final CopyCondition condition;
  final ValueChanged<CopyCondition> onConditionChanged;

  /// Commits the return. Null while nothing has been scanned.
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return SectionCard(
      title: l10n.returnsSummarySection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDetailRow(
            label: l10n.returnsSummaryCopies,
            child: Text('$copyCount'),
          ),
          SizedBox(height: spacing.sm),
          AppDetailRow(
            label: l10n.returnsSummaryLate,
            child: Text(
              '$lateCount',
              style: context.textTheme.bodyMedium?.copyWith(
                color: lateCount == 0 ? scheme.onSurface : scheme.error,
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
          AppDetailRow(
            label: l10n.returnsSummaryFines,
            child: Text(
              finesDue.display(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: finesDue.isZero ? scheme.onSurface : scheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: spacing.md),
          AppDropdownField<CopyCondition>(
            label: l10n.returnsConditionSection,
            value: condition,
            items: CopyCondition.values,
            itemLabel: (value) => value.label(l10n),
            onChanged: (value) => onConditionChanged(value ?? condition),
          ),
          SizedBox(height: spacing.xxs),
          Text(
            l10n.returnsConditionDescription,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.md),
          AppCheckboxField(
            value: waiveFines,
            label: l10n.returnsWaiveFines,
            description: l10n.returnsWaiveFinesDescription,
            onChanged: (value) => onWaiveChanged(value ?? false),
          ),
          SizedBox(height: spacing.lg),
          AppButton(
            onPressed: onConfirm,
            child: Text(l10n.returnsConfirm),
          ),
        ],
      ),
    );
  }
}

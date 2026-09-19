// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// The erase entry: one quiet ledger row, not an alarm panel.
///
/// There is no warning icon and no red wash - the page already says what the
/// library is, so restating it in red reads as decoration. The danger lives
/// in exactly one place: the outlined destructive button, which is the
/// design system's own idiom for a destructive control on a page. The
/// confirmation dialog behind it is what stops an accident, not the card.
class SettingsEraseCard extends StatelessWidget {
  const SettingsEraseCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.isLoading = false,
    super.key,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  /// Shows the button's spinner and disables it while the erase runs.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: spacing.xxs),
          Text(
            description,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: spacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              variant: AppButtonVariant.destructive,
              isLoading: isLoading,
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

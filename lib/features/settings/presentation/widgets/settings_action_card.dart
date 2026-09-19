// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// One routine data operation: what it does, and the control that starts it.
///
/// Routine only — the erase entry has its own card with the danger carried
/// by its button rather than a wash around it.
class SettingsActionCard extends StatelessWidget {
  const SettingsActionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.icon,
    this.isLoading = false,
    super.key,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final AppIconSpec icon;

  /// Shows the action button's spinner and disables it — a card whose
  /// action restarts the app on success has nowhere else to put that state.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            icon,
            size: spacing.lg - 2,
            color: AppStatusTone.brand.foreground(context),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
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
                    variant: AppButtonVariant.outline,
                    isLoading: isLoading,
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

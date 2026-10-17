// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// Warns that the browser may clear the catalogue on its own, with the one
/// action that changes that.
///
/// Shown on the backup page only on the web, and only while the browser has
/// not promised to keep the catalogue's storage.
class SettingsStorageNoticeCard extends StatelessWidget {
  const SettingsStorageNoticeCard({
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
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return AppCard(
      tone: AppStatusTone.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            AppIcons.warning,
            size: spacing.lg - 2,
            color: AppStatusTone.warning.foreground(context),
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

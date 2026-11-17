// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/presentation/widgets/copy_status_badge.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One copy as a card, for the window classes too narrow for the table.
class CopyCard extends StatelessWidget {
  const CopyCard({
    required this.copy,
    required this.onTap,
    this.actions = const [],
    super.key,
  });

  final Copy copy;
  final VoidCallback onTap;

  /// The overflow menu. Empty for a role that may read the catalogue but not
  /// change it - no menu is drawn then.
  final List<AppMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    copy.barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (copy.archivedAt != null)
                  AppStatusBadge(label: context.l10n.catalogArchivedBadge)
                else
                  CopyStatusBadge(status: copy.status),
                if (actions.isNotEmpty)
                  AppMenuButton(
                    tooltip: context.l10n.commonMoreActions,
                    actions: actions,
                  ),
              ],
            ),
            SizedBox(height: spacing.xxs),
            Text(
              copy.titleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              copy.shelf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

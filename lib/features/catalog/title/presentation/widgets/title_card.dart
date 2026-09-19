// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

class TitleCard extends StatelessWidget {
  const TitleCard({required this.title, required this.onTap, super.key});

  final catalog.Title title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final isAvailable = title.availableCount > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(
              title.formatCode.formatIcon,
              size: spacing.md + 4,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    title.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Row(
                    children: [
                      AppStatusBadge(
                        dense: true,
                        label: isAvailable
                            ? l10n.statusAvailable
                            : l10n.statusOnLoan,
                        tone: isAvailable
                            ? AppStatusTone.success
                            : AppStatusTone.brand,
                      ),
                      SizedBox(width: spacing.xs),
                      Flexible(
                        child: Text(
                          l10n.titlesCopiesOf(
                            '${title.availableCount}',
                            '${title.copyCount}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One article, as the guide's landing page offers it.
///
/// The summary is not decoration: a reader arriving with a problem rather
/// than a section name picks the card by what it promises, so a card whose
/// body is only its own title is a card they have to open to evaluate.
class GuideTopicCard extends StatelessWidget {
  const GuideTopicCard({
    required this.article,
    required this.onTap,
    super.key,
  });

  /// The article the card stands for.
  final GuideArticle article;

  /// Opens it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final l10n = context.l10n;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(context.appRadius.item),
                ),
                child: AppIcon(
                  article.topic.icon,
                  size: 18,
                  color: colors.brandStrong,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  article.title,
                  style: type.sectionTitle.copyWith(color: colors.textHigh),
                ),
              ),
              AppIcon(
                AppIcons.chevronRight,
                size: 16,
                color: colors.ink400,
                matchTextDirection: true,
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            article.summary,
            style: type.body.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: spacing.sm),
          Text(
            l10n.guideSectionCount(article.sections.length),
            style: type.micro.copyWith(color: colors.ink400),
          ),
        ],
      ),
    );
  }
}

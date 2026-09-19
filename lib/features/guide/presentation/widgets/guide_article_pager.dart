// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What to read before this article, and what to read after it.
///
/// The manual has an order - set the library up, then watch it, then work it
/// - and a reader who arrived from a search result has no way of knowing
/// that. The pager is what turns eight separate articles back into a book.
class GuideArticlePager extends StatelessWidget {
  const GuideArticlePager({
    required this.previous,
    required this.next,
    required this.onOpen,
    super.key,
  });

  /// The article before this one, if there is one.
  final GuideArticle? previous;

  /// The article after it, if there is one.
  final GuideArticle? next;

  /// Opens one.
  final void Function(GuideArticle article) onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final l10n = context.l10n;

    // The two cards match heights so a long title on one side does not leave
    // the other floating. Stretch needs a measured height to stretch to, and
    // a row in a scrolling column has none until IntrinsicHeight supplies it.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: previous == null
                ? const SizedBox.shrink()
                : _PagerCard(
                    label: l10n.guidePreviousLabel,
                    article: previous!,
                    trailing: false,
                    onTap: () => onOpen(previous!),
                  ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: next == null
                ? const SizedBox.shrink()
                : _PagerCard(
                    label: l10n.guideNextLabel,
                    article: next!,
                    trailing: true,
                    onTap: () => onOpen(next!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PagerCard extends StatelessWidget {
  const _PagerCard({
    required this.label,
    required this.article,
    required this.trailing,
    required this.onTap,
  });

  final String label;
  final GuideArticle article;
  final bool trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;

    final text = Column(
      crossAxisAlignment: trailing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: type.micro.copyWith(color: colors.ink400)),
        SizedBox(height: spacing.xxs),
        Text(
          article.title,
          textAlign: trailing ? TextAlign.end : TextAlign.start,
          style: type.label.copyWith(color: colors.textHigh),
        ),
      ],
    );

    final chevron = AppIcon(
      trailing ? AppIcons.chevronRight : AppIcons.chevronLeft,
      size: 16,
      color: colors.ink400,
      matchTextDirection: true,
    );

    return AppCard(
      onTap: onTap,
      child: Row(
        children: trailing
            ? [Expanded(child: text), SizedBox(width: spacing.xs), chevron]
            : [chevron, SizedBox(width: spacing.xs), Expanded(child: text)],
      ),
    );
  }
}

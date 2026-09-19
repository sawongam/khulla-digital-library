// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/features/guide/presentation/guide_content.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_article_pager.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_block_view.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_contents_panel.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One article of the manual.
///
/// The contents panel sits *outside* the scroll view rather than at the top
/// of it, which is what makes it stay put while the prose moves — the same
/// reason the shell's top bar lives in the shell. Below a large window there
/// is no column to spare for it, and the reader has the landing page's list
/// instead.
class GuideArticlePage extends StatefulWidget {
  const GuideArticlePage({required this.topic, this.anchor, super.key});

  /// Which article, or null when the URL named one that does not exist.
  final GuideTopic? topic;

  /// A section to open at, from a search result's link.
  final String? anchor;

  @override
  State<GuideArticlePage> createState() => _GuideArticlePageState();
}

class _GuideArticlePageState extends State<GuideArticlePage> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _anchors = {};
  String? _active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToAnchor());
  }

  @override
  void didUpdateWidget(GuideArticlePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The branch keeps this page alive, so arriving from a second search
    // result — or the pager's previous/next — is a widget update rather
    // than a fresh mount. The scroll offset would otherwise stay where the
    // last article left it, greeting the reader with its footer.
    if (widget.topic != oldWidget.topic) {
      _anchors.clear();
      _active = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.anchor != null) {
          _jumpToAnchor();
        } else {
          _scrollToTop();
        }
      });
    } else if (widget.anchor != oldWidget.anchor) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToAnchor());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToAnchor() {
    final anchor = widget.anchor;
    if (anchor == null || !mounted) return;
    final key = _anchors[anchor]?.currentContext;
    if (key == null) return;
    Scrollable.ensureVisible(
      key,
      duration: context.appMotion.layout,
      alignment: 0.05,
    );
  }

  /// A new article opens at its top — it is never a continuation of the
  /// scroll the reader just left.
  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(0);
  }

  /// The heading nearest the top of the viewport, for the contents panel.
  ///
  /// Read from the laid-out boxes rather than from a table of offsets: the
  /// sections are different heights, the window resizes, and the prose
  /// reflows — every one of which would invalidate a cached offset.
  void _updateActive(GuideArticle article) {
    String? nearest;
    for (final section in article.sections) {
      final box =
          _anchors[section.anchor]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= 160) nearest = section.anchor;
    }
    if (nearest != _active) setState(() => _active = nearest);
  }

  void _open(GuideArticle article) =>
      context.go(Routes.guideTopic(article.topic.slug));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final topic = widget.topic;

    if (topic == null) {
      return AppPageBody(
        child: AppEmptyView(
          icon: AppIcons.noResults,
          title: l10n.guideNotFoundTitle,
          message: l10n.guideNotFoundBody,
          actionLabel: l10n.guideBackToGuide,
          onAction: () => context.go(Routes.guide),
        ),
      );
    }

    final articles = guideArticles(l10n);
    final index = articles.indexWhere((a) => a.topic == topic);
    final article = articles[index];

    for (final section in article.sections) {
      _anchors.putIfAbsent(section.anchor, GlobalKey.new);
    }

    final body = NotificationListener<ScrollUpdateNotification>(
      onNotification: (_) {
        _updateActive(article);
        return false;
      },
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          spacing.page,
          spacing.lg,
          spacing.page,
          spacing.xlg,
        ),
        child: AppContentConstraint.wide(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ArticleHeader(article: article),
              SizedBox(height: spacing.lg),
              for (final section in article.sections) ...[
                KeyedSubtree(
                  key: _anchors[section.anchor],
                  child: AppSectionHeader(title: section.title),
                ),
                SizedBox(height: spacing.sm),
                for (final block in section.blocks) ...[
                  GuideBlockView(block),
                  SizedBox(height: spacing.md),
                ],
                SizedBox(height: spacing.md),
              ],
              GuideArticlePager(
                previous: index == 0 ? null : articles[index - 1],
                next: index == articles.length - 1 ? null : articles[index + 1],
                onOpen: _open,
              ),
            ],
          ),
        ),
      ),
    );

    if (context.formFactor != FormFactor.large) {
      return AppPageBody(wide: true, child: body);
    }

    return AppPageBody(
      wide: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: body),
          SizedBox(
            width: 230,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, spacing.lg, spacing.page, 0),
              child: GuideContentsPanel(
                article: article,
                activeAnchor: _active,
                onSelected: (section) => Scrollable.ensureVisible(
                  _anchors[section.anchor]!.currentContext!,
                  duration: context.appMotion.layout,
                  alignment: 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The article's own header: what it is, and the screen it describes.
class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({required this.article});

  final GuideArticle article;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.brandSoft,
                borderRadius: BorderRadius.circular(context.appRadius.item),
              ),
              child: AppIcon(
                article.topic.icon,
                size: 20,
                color: colors.brandStrong,
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: type.pageHeader.copyWith(color: colors.textHigh),
                  ),
                  Text(
                    l10n.guideSectionCount(article.sections.length),
                    style: type.micro.copyWith(color: colors.ink400),
                  ),
                ],
              ),
            ),
            // Beside the title rather than on a row of its own: the header
            // already spans an icon, a title and a summary, and a lone
            // button row underneath is pure height.
            if (article.route case final route?) ...[
              SizedBox(width: spacing.sm),
              AppButton(
                variant: AppButtonVariant.outline,
                icon: AppIcons.openExternal,
                onPressed: () => context.go(route),
                child: Text(l10n.guideOpenScreen),
              ),
            ],
          ],
        ),
        SizedBox(height: spacing.sm),
        Text(
          article.summary,
          style: type.bodyLarge.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

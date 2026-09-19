// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A labelled drawing of the screen a section is describing.
///
/// Deliberately a drawing rather than a screenshot. A screenshot is a
/// light-mode PNG of an English window at one density: it goes stale the week
/// a button moves, it cannot be translated, and it lands in a dark-mode
/// window as a white rectangle. This is built from the same tokens the real
/// screen is and carries the same localized labels, so it follows the theme,
/// the brand colour and the locale for free.
///
/// It is drawn from the real labels rather than invented ones, and it never
/// shows a figure: a number made up for a diagram is a number somebody quotes
/// back. Bars stand in for values.
class GuideScreenMock extends StatelessWidget {
  const GuideScreenMock(this.shot, {super.key});

  /// What to draw, and what the numbered legend under it says.
  final GuideScreenshot shot;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          filled: true,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MockChrome(caption: shot.caption),
              Padding(
                padding: EdgeInsets.all(spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, part) in shot.parts.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index == shot.parts.length - 1
                              ? 0
                              : spacing.sm,
                        ),
                        child: _MarkedPart(part: part),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (shot.markers.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          for (final (index, note) in shot.markers.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MarkerChip(number: index + 1),
                  SizedBox(width: spacing.xs),
                  Expanded(
                    child: Text(
                      note,
                      style: type.caption.copyWith(color: colors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// The window furniture around the drawing: a stub of the rail and a top bar
/// carrying the caption, so the reader places the drawing inside the app
/// before reading a single label.
class _MockChrome extends StatelessWidget {
  const _MockChrome({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.hairline.withValues(alpha: 0.35),
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsetsDirectional.only(end: spacing.xxs),
                child: const _Bar(width: 6, height: 6, radius: 3),
              ),
            SizedBox(width: spacing.xs),
            Expanded(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.micro.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One band of the drawing, with its legend number in the leading gutter.
///
/// The number sits beside the band rather than on top of it: a chip floated
/// over a table header covers the very label it is pointing at.
class _MarkedPart extends StatelessWidget {
  const _MarkedPart({required this.part});

  final GuideMockPart part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final number = part.marker;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: number == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(top: spacing.xxs),
                  child: _MarkerChip(number: number),
                ),
        ),
        SizedBox(width: spacing.xxs),
        Expanded(child: _PartBody(part: part)),
      ],
    );
  }
}

/// The switch from a declared part to its drawing.
class _PartBody extends StatelessWidget {
  const _PartBody({required this.part});

  final GuideMockPart part;

  @override
  Widget build(BuildContext context) => switch (part) {
    final GuideMockToolbar toolbar => _MockToolbar(toolbar),
    final GuideMockStats stats => _MockStats(stats),
    final GuideMockTable table => _MockTable(table),
    final GuideMockForm form => _MockForm(form),
    final GuideMockList list => _MockList(list),
    final GuideMockCards cards => _MockCards(cards),
  };
}

class _MockToolbar extends StatelessWidget {
  const _MockToolbar(this.part);

  final GuideMockToolbar part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: _Panel(
            child: Row(
              children: [
                AppIcon(AppIcons.search, size: 12, color: colors.ink400),
                SizedBox(width: spacing.xxs),
                Expanded(
                  child: Text(
                    part.search,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextStyles.micro.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (part.action case final label?) ...[
          SizedBox(width: spacing.xs),
          _Pill(label: label),
        ],
      ],
    );
  }
}

class _MockStats extends StatelessWidget {
  const _MockStats(this.part);

  final GuideMockStats part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Row(
      children: [
        for (final (index, label) in part.labels.indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == part.labels.length - 1 ? 0 : spacing.xs,
              ),
              child: _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.micro.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    SizedBox(height: spacing.xxs),
                    // A bar, not a figure: an invented count on a diagram is
                    // a count somebody repeats as fact.
                    _Bar(width: 26 + index * 4.0, height: 8, strong: true),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MockTable extends StatelessWidget {
  const _MockTable(this.part);

  final GuideMockTable part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final tone = part.tone;

    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.xs,
              vertical: spacing.xxs,
            ),
            child: Row(
              children: [
                for (final column in part.columns)
                  Expanded(
                    child: Text(
                      column,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.micro.copyWith(
                        color: colors.textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var row = 0; row < part.rows; row++)
            DecoratedBox(
              decoration: BoxDecoration(
                color: tone != null && row == part.rows - 1
                    ? tone.background(context)
                    : null,
                border: Border(top: BorderSide(color: colors.hairline)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.xs,
                  vertical: spacing.xs,
                ),
                child: Row(
                  children: [
                    for (var column = 0; column < part.columns.length; column++)
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _Bar(
                            width: 54 - column * 12 - (row % 2) * 6,
                            height: 6,
                            color: tone != null && row == part.rows - 1
                                ? tone.foreground(context)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MockForm extends StatelessWidget {
  const _MockForm(this.part);

  final GuideMockForm part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final field in part.fields) ...[
            Text(
              field,
              style: context.appTextStyles.micro.copyWith(
                color: colors.textHigh,
              ),
            ),
            SizedBox(height: spacing.xxs),
            Container(
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: colors.hairline),
                borderRadius: BorderRadius.circular(context.appRadius.control),
              ),
            ),
            SizedBox(height: spacing.xs),
          ],
          if (part.submit case final label?)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _Pill(label: label),
            ),
        ],
      ),
    );
  }
}

class _MockList extends StatelessWidget {
  const _MockList(this.part);

  final GuideMockList part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var row = 0; row < part.rows; row++)
            Padding(
              padding: EdgeInsets.only(
                bottom: row == part.rows - 1 ? 0 : spacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.brandSoft,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: spacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(width: 90 - row * 14.0, height: 6, strong: true),
                        SizedBox(height: spacing.xxs),
                        _Bar(width: 130 - row * 20.0, height: 5),
                      ],
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

class _MockCards extends StatelessWidget {
  const _MockCards(this.part);

  final GuideMockCards part;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Row(
      children: [
        for (final (index, label) in part.labels.indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == part.labels.length - 1 ? 0 : spacing.xs,
              ),
              child: _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.micro.copyWith(
                        color: context.appColors.textHigh,
                      ),
                    ),
                    SizedBox(height: spacing.xxs),
                    const _Bar(width: 40, height: 5),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A surface inside the drawing - a card, a field, a table's box.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: padding ?? EdgeInsets.all(context.appSpacing.xs),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(context.appRadius.item),
      ),
      child: child,
    );
  }
}

/// A filled button inside the drawing.
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xs,
        vertical: spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(context.appRadius.control),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.appTextStyles.micro.copyWith(
          color: context.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// A stand-in for text or a value the drawing deliberately does not invent.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    this.radius = 2,
    this.strong = false,
    this.color,
  });

  final double width;
  final double height;
  final double radius;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (color ?? (strong ? colors.ink400 : colors.ink300)).withValues(
          alpha: strong ? 0.55 : 0.35,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// The numbered chip that ties a band of the drawing to its legend entry.
class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.colorScheme.primary,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      style: context.appTextStyles.micro.copyWith(
        color: context.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    ),
  );
}

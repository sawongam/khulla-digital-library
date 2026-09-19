// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// One row of an [AppTable] or [AppSliverTable].
///
/// Rows are separated by a **zebra stripe**, not by rules: at ~52px per row a
/// hairline every line turns a long table into a grid of boxes, while a 10%
/// tint on even rows reads as texture and lets the eye track across a 1600px
/// window. Hover and selection are tints of the same family, one step
/// stronger each, so the three states never compete.
///
/// The row's height comes from [AppMetrics.tableRowHeight] in the theme -
/// one global token for every table in the app.
class AppTableRow<T> extends StatefulWidget {
  const AppTableRow({
    required this.item,
    required this.columns,
    required this.index,
    this.onTap,
    this.selected = false,
    this.divided = false,
    super.key,
  });

  /// The record this row renders.
  final T item;

  /// Its position in the list, which decides whether it is striped.
  final int index;

  /// The full column set; the ones too wide for this window are dropped.
  final List<AppTableColumn<T>> columns;

  /// Opens the record. Null leaves the row inert.
  final VoidCallback? onTap;

  /// Whether this row is the picked one.
  final bool selected;

  /// Draws a hairline under the row. Off by default - the zebra stripe is
  /// the separator. Turn it on only for a short table inside a card, where
  /// there are too few rows for a stripe to read as a pattern.
  final bool divided;

  @override
  State<AppTableRow<T>> createState() => _AppTableRowState<T>();
}

class _AppTableRowState<T> extends State<AppTableRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final tints = colors.tints;
    final metrics = context.appMetrics;
    final visible = AppTableColumn.visible(widget.columns, context.formFactor);
    final interactive = widget.onTap != null;
    final rowHeight = metrics.tableRowHeight;
    final motion = context.appMotion;
    final showOverlay = widget.selected || (_hovered && interactive);
    final overlayColor = widget.selected ? tints.rowSelected : tints.rowHover;

    final content = SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final column in visible)
            column.sized(
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.md,
                  vertical: metrics.tableCellPaddingY,
                ),
                child: Align(
                  alignment: column.alignment,
                  child: DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextStyles.body.copyWith(
                      color: colors.ink100,
                    ),
                    child: column.cellBuilder(context, widget.item),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: widget.divided
              ? Border(bottom: BorderSide(color: colors.hairline))
              : null,
        ),
        child: Stack(
          children: [
            if (widget.index.isOdd)
              Positioned.fill(child: ColoredBox(color: tints.rowZebra)),
            // Fade the tint in rather than lerping to it. AnimatedContainer
            // from Colors.transparent lerps through black (transparent is
            // 0x00000000), which reads as a dark-theme grey for a frame.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: motion.color,
                  opacity: showOverlay ? 1 : 0,
                  child: ColoredBox(color: overlayColor),
                ),
              ),
            ),
            if (interactive)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: content,
              )
            else
              content,
          ],
        ),
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The footer under a table: how much is showing, and how to move.
///
/// The range label is handed in ready-made - "Showing 1–9 of 36" is a
/// sentence with plurals and digit grouping in it, which is an ARB's job, not
/// a widget's.
///
/// Numbered pages appear only when [pageCount] is set. They matter on a
/// catalogue: "jump to page 7" is how a librarian returns to where they were
/// before answering the phone, and prev/next alone cannot do it. Past seven
/// pages the run is elided around the current one, so the footer never wraps.
///
/// Two conventions here run against the usual instinct and are deliberate.
/// The **current page is a filled brand chip** - the reference dashboard
/// treats pagination as navigation chrome, not a primary action, but the
/// filled square reads clearly at table scale. And the prev/next controls are
/// **hidden at the ends rather than disabled**, so there is no permanently
/// greyed-out control sitting under the table.
class AppPagination extends StatelessWidget {
  const AppPagination({
    required this.rangeLabel,
    required this.onPrevious,
    required this.onNext,
    required this.previousTooltip,
    required this.nextTooltip,
    this.pageSizeControl,
    this.pageCount = 0,
    this.currentPage = 0,
    this.onPageSelected,
    super.key,
  });

  /// "Showing 1–9 of 36 titles", already localized.
  final String rangeLabel;

  /// Null disables the control - the first page has nowhere back to go.
  final VoidCallback? onPrevious;

  /// Null disables the control.
  final VoidCallback? onNext;

  /// Tooltip for the previous control.
  final String previousTooltip;

  /// Tooltip for the next control.
  final String nextTooltip;

  /// The rows-per-page picker, if the screen offers one.
  final Widget? pageSizeControl;

  /// How many pages there are. Zero hides the numbered run.
  final int pageCount;

  /// The active page, zero-based.
  final int currentPage;

  /// Called with a zero-based page index.
  final ValueChanged<int>? onPageSelected;

  /// Which page numbers to draw for a run of [count] around [current].
  ///
  /// A null entry is an ellipsis. Kept static and pure so the elision rule is
  /// testable without pumping a widget.
  static List<int?> pageWindow(int count, int current, {int maxVisible = 7}) {
    if (count <= maxVisible) return List<int?>.generate(count, (i) => i);

    final pages = <int?>[0];
    var start = current - 1;
    var end = current + 1;
    if (current <= 2) {
      start = 1;
      end = 3;
    } else if (current >= count - 3) {
      start = count - 4;
      end = count - 2;
    }

    if (start > 1) pages.add(null);
    for (var page = start; page <= end; page++) {
      if (page > 0 && page < count - 1) pages.add(page);
    }
    if (end < count - 2) pages.add(null);
    pages.add(count - 1);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final sizeControl = pageSizeControl;
    final selectPage = onPageSelected;
    final showNumbers = pageCount > 1 && selectPage != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: spacing.sm,
        spacing: spacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sizeControl != null) ...[
                sizeControl,
                SizedBox(width: spacing.sm),
              ],
              Text(
                rangeLabel,
                style: context.appTextStyles.body.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onPrevious != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.xxs / 2),
                  child: _NavButton(
                    icon: AppIcons.chevronLeft,
                    tooltip: previousTooltip,
                    onTap: onPrevious!,
                  ),
                ),
              if (showNumbers)
                for (final page in pageWindow(pageCount, currentPage))
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.xxs / 2),
                    child: page == null
                        ? SizedBox(
                            width: context.appMetrics.iconButtonMedium,
                            child: Text(
                              '…',
                              textAlign: TextAlign.center,
                              style: context.appTextStyles.body.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          )
                        : _PageButton(
                            page: page,
                            selected: page == currentPage,
                            onTap: () => selectPage(page),
                          ),
                  ),
              if (onNext != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.xxs / 2),
                  child: _NavButton(
                    icon: AppIcons.chevronRight,
                    tooltip: nextTooltip,
                    onTap: onNext!,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final metrics = context.appMetrics;
    final radius = BorderRadius.circular(context.appRadius.container);
    final side = metrics.paginationItem;

    return AppRipple(
      onTap: onTap,
      borderRadius: radius,
      pressScale: 1,
      child: Container(
        constraints: BoxConstraints(minWidth: side, minHeight: side),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: context.appSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? colors.brand : scheme.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? colors.brand : colors.hairline,
          ),
        ),
        child: Text(
          '${page + 1}',
          style: context.appTextStyles.label.copyWith(
            color: selected ? scheme.onPrimary : colors.ink500,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final AppIconSpec icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final metrics = context.appMetrics;
    final radius = BorderRadius.circular(context.appRadius.container);
    final side = metrics.paginationItem;

    return Tooltip(
      message: tooltip,
      child: AppRipple(
        onTap: onTap,
        borderRadius: radius,
        pressScale: 1,
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: radius,
            border: Border.all(color: colors.hairline),
          ),
          child: AppIcon(icon, size: metrics.icon, color: colors.ink500),
        ),
      ),
    );
  }
}

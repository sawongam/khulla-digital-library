// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The modal bottom sheet: 10px top corners, a grab handle, and keyboard-safe
/// padding, over a scrim that dims hard.
///
/// The handle is the whole dismiss affordance - a slim 32×4 pill 12px from
/// the top edge - rather than a floating close button. On a phone the gesture
/// is the drag, and a chip in the corner is both a smaller target and a
/// second way to say the same thing.
///
/// Pass [actions] to pin a button row to the bottom of the sheet. Actions sit
/// outside the scrolling body, so a sheet whose content grows - an extra field,
/// a photo picker - never scrolls its confirm button out of reach.
///
/// Use [AppBottomSheet.show] to present a sheet with this chrome. The sheet's
/// corner radius and background also come from [ThemeData.bottomSheetTheme],
/// so a raw `showModalBottomSheet` call picks up the same rounding even
/// without this wrapper.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.title,
    required this.child,
    this.caption,
    this.titleTrailing,
    this.actions,
    this.expandBody = false,
    super.key,
  });

  final String title;
  final String? caption;

  /// Optional control pinned to the trailing edge of the title row.
  final Widget? titleTrailing;
  final Widget child;

  /// Pinned below the scrolling body, typically a cancel/confirm button row.
  final Widget? actions;

  /// When true, the body expands to fill a fixed-height sheet.
  final bool expandBody;

  /// Default fraction of screen height for sheets with scrollable content.
  static const double defaultHeightFactor = 0.7;

  /// Presents [child] (built lazily via [builder]) wrapped in the standard
  /// sheet chrome, and resolves to whatever the sheet is popped with.
  ///
  /// [heightFactor] sets a fixed sheet height as a fraction of the screen
  /// (e.g. [defaultHeightFactor] or `0.8` for a tall picker). Omit for the
  /// default intrinsic height - only suitable for short, non-scrolling content.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    String? caption,
    WidgetBuilder? titleTrailingBuilder,
    WidgetBuilder? actionsBuilder,
    bool isScrollControlled = true,
    double? heightFactor,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (sheetContext) {
      final expandBody = heightFactor != null;
      final sheet = AppBottomSheet(
        title: title,
        caption: caption,
        titleTrailing: titleTrailingBuilder == null
            ? null
            : Builder(builder: titleTrailingBuilder),
        expandBody: expandBody,
        actions: actionsBuilder == null
            ? null
            : Builder(builder: actionsBuilder),
        child: Builder(builder: builder),
      );
      if (heightFactor == null) return sheet;

      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * heightFactor,
        child: sheet,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final captionText = caption;
    final trailing = titleTrailing;
    final actionRow = actions;

    return SizedBox(
      width: double.infinity,
      height: expandBody ? double.infinity : null,
      child: Column(
        mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: spacing.sm, bottom: spacing.xs),
            child: Container(
              width: spacing.xlg,
              height: spacing.xxs,
              decoration: BoxDecoration(
                color: colors.muted.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(context.appRadius.pill),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.page,
                    spacing.xs,
                    spacing.page,
                    spacing.md,
                  ),
                  child: Column(
                    mainAxisSize: expandBody
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.appTextStyles.title.copyWith(
                                color: colors.ink200,
                              ),
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                      if (captionText != null) ...[
                        SizedBox(height: spacing.xxs),
                        Text(
                          captionText,
                          style: context.appTextStyles.body.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                      SizedBox(height: spacing.md),
                      // A fixed-height sheet cannot size to its content, so the
                      // body scrolls: a plain Column of rows here is the
                      // 116px-overflow the category sheet hit. Callers that
                      // already scroll (the *More* list) size themselves to
                      // their content inside this, so the outer view does the
                      // scrolling and nothing nests badly.
                      if (expandBody)
                        Expanded(child: SingleChildScrollView(child: child))
                      else
                        child,
                      if (actionRow != null) ...[
                        SizedBox(height: spacing.md),
                        actionRow,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

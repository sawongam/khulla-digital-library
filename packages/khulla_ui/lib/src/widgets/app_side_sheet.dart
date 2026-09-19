// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_side_sheet}
/// A modal editor panel that enters from the trailing edge on a window and
/// from the bottom on a phone.
///
/// One call for both, because the same *Edit member* form is reached from a
/// desktop rail and a phone browser tab, and a sheet that slides up on a
/// 1600px monitor wastes the room the form needs. Below
/// [FormFactor.medium] it hands off to [AppBottomSheet] unchanged, so the
/// compact behaviour stays exactly what the rest of the app does.
///
/// The close control is a **chip floating outside the panel's leading edge**,
/// not a button in its corner. It costs nothing inside the panel, which is
/// where the form needs the room, and it reads as "this closes the whole
/// thing" rather than as one more control in the header.
///
/// It opens over 500ms and closes over 300ms - the one deliberately slow
/// movement in the product, and asymmetric because dismissal should never
/// feel like waiting.
///
/// Actions are pinned below the scrolling body: a form that grows an extra
/// field must never scroll its *Save* out of reach.
/// {@endtemplate}
class AppSideSheet extends StatelessWidget {
  /// {@macro app_side_sheet}
  const AppSideSheet({
    required this.title,
    required this.child,
    required this.closeTooltip,
    this.caption,
    this.actions,
    this.width = 448,
    super.key,
  });

  /// The panel heading, already localized.
  final String title;

  /// The scrolling body - typically a [Column] of [AppFormSection]s.
  final Widget child;

  /// Tooltip on the close control.
  final String closeTooltip;

  /// Supporting line under [title].
  final String? caption;

  /// Pinned action row, primary trailing.
  final Widget? actions;

  /// Panel width on a wide window. It never exceeds 90% of the window, so a
  /// half-size window still shows the page behind it.
  final double width;

  /// Presents the panel and resolves to whatever it is popped with.
  ///
  /// Uses a bottom sheet below [FormFactor.medium] and a trailing-edge panel
  /// above it.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String closeTooltip,
    required WidgetBuilder builder,
    String? caption,
    WidgetBuilder? actionsBuilder,
    double width = 448,
    bool barrierDismissible = true,
    String barrierLabel = 'Dismiss',
  }) {
    if (!context.formFactor.usesNavigationRail) {
      return AppBottomSheet.show<T>(
        context: context,
        title: title,
        caption: caption,
        builder: builder,
        actionsBuilder: actionsBuilder,
        heightFactor: AppBottomSheet.defaultHeightFactor,
      );
    }

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: context.appColors.tints.scrimDialog,
      transitionDuration: context.appMotion.sheetOpen,
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: AppSideSheet(
          title: title,
          caption: caption,
          closeTooltip: closeTooltip,
          width: width,
          actions: actionsBuilder == null
              ? null
              : Builder(builder: actionsBuilder),
          child: Builder(builder: builder),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: context.appMotion.standard,
              ),
            ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final captionText = caption;
    final actionRow = actions;
    final windowWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = width.clamp(0.0, windowWidth * 0.75);

    final panel = Material(
      color: scheme.surface,
      shape: BorderDirectional(start: BorderSide(color: colors.hairline)),
      child: SizedBox(
        width: panelWidth,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: context.appTextStyles.formTitle.copyWith(
                    color: colors.ink200,
                  ),
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
                SizedBox(height: spacing.lg),
                Expanded(child: SingleChildScrollView(child: child)),
                if (actionRow != null) ...[
                  SizedBox(height: spacing.md),
                  actionRow,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // The chip only fits outside the panel when there is page left to hang it
    // over; on a narrow window it moves inside the header instead.
    final chipFits = windowWidth - panelWidth > 96;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chipFits)
          Padding(
            padding: EdgeInsets.only(top: spacing.lg, right: spacing.lg),
            child: _SheetCloseChip(
              tooltip: closeTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        panel,
      ],
    );
  }
}

/// The close chip that hangs beside a side sheet: a 45px bordered square with
/// a brand glyph.
class _SheetCloseChip extends StatelessWidget {
  const _SheetCloseChip({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  static const double _size = 45;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(context.appRadius.container);

    return Tooltip(
      message: tooltip,
      child: AppRipple(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: radius,
            border: Border.all(color: colors.hairline),
            boxShadow: context.appShadows.card,
          ),
          child: AppIcon(
            AppIcons.close,
            size: context.appMetrics.iconLarge,
            color: colors.brand,
          ),
        ),
      ),
    );
  }
}

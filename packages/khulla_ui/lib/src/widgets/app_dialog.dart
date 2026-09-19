// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// How wide a dialog is allowed to get.
///
/// A dialog is sized by the shape of its content, not by the screen. A
/// confirmation is [md]; a form is [xl], which is the width most of the
/// product's dialogs use.
enum AppDialogWidth {
  /// 384px - a single short question.
  sm(384),

  /// 448px - the confirmation default.
  md(448),

  /// 512px - a short form.
  lg(512),

  /// 576px - the canonical form dialog.
  xl(576),

  /// 672px - a two-column form.
  xxl(672),

  /// 768px - a form with a table or a preview in it.
  xxxl(768),

  /// 864px - the widest a dialog goes: long prose that needs a comfortable
  /// measure, or a two-column form beside a preview. Past this, the content
  /// wants a page rather than a panel over one.
  xxxxl(864);

  AppDialogWidth(this.value);

  /// The cap, in logical pixels.
  final double value;
}

/// {@template app_dialog}
/// The system's modal chrome.
///
/// Three details carry the product's character and are the reason a screen
/// must never hand-roll a `Dialog`:
///
/// * the **close chip floats outside the top-right corner**, shifts a little
///   further out on hover and rotates its glyph 90° - this is the single most
///   recognisable interaction in the design language;
/// * the body scrolls **inside** the dialog at a 90% viewport-height cap, so
///   a long form never pushes the footer off screen;
/// * the footer is a right-aligned row on a wide window and an equal-width
///   row on a narrow one, which keeps the confirming action under the
///   thumb on a phone.
///
/// Use [AppDialog.show] for arbitrary content and [AppDialog.confirmDestructive]
/// for the "delete this?" prompt - same chrome as [AppFormModal]: left-aligned
/// [AppTextStyles.displaySmall] title, body copy, [AppDialogWidth.sm], and a
/// filled destructive confirm.
/// {@endtemplate}
class AppDialog extends StatelessWidget {
  /// {@macro app_dialog}
  const AppDialog({
    required this.actions,
    this.title,
    this.message,
    this.content,
    this.width = AppDialogWidth.md,
    this.icon,
    this.iconWidget,
    this.iconTone = AppStatusTone.danger,
    this.showClose = true,
    super.key,
  });

  /// The dialog's heading, already localized. Omit it for content that
  /// carries its own heading - the about panel, say, which opens on the
  /// product's name.
  final String? title;

  /// The supporting line under the heading.
  final String? message;

  /// Arbitrary body content between the message and the actions.
  final Widget? content;

  /// The button row. Compose it with [AppDialog.primaryAction] and friends.
  final Widget actions;

  /// The width cap.
  final AppDialogWidth width;

  /// A glyph in a tinted circular badge above the title.
  final AppIconSpec? icon;

  /// A custom badge glyph, taking precedence over [icon].
  final Widget? iconWidget;

  /// Which wash and ink the badge uses.
  final AppStatusTone iconTone;

  /// Whether to draw the close chip. Hide it for a step the operator must
  /// answer rather than dismiss.
  final bool showClose;

  /// Presents an [AppDialog] and resolves to whatever it is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder actionsBuilder,
    String? title,
    String? message,
    Widget? content,
    AppDialogWidth width = AppDialogWidth.md,
    AppIconSpec? icon,
    Widget? iconWidget,
    AppStatusTone iconTone = AppStatusTone.danger,
    bool barrierDismissible = true,
    bool showClose = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      content: content,
      width: width,
      icon: iconWidget == null ? icon : null,
      iconWidget: iconWidget,
      iconTone: iconTone,
      showClose: showClose,
      actions: Builder(builder: actionsBuilder),
    ),
  );

  /// Confirms a destructive action. Resolves true only on confirm.
  ///
  /// Uses [AppFormModal] so the prompt matches create/edit chrome: heading
  /// size, description, small width, and a filled danger confirm.
  static Future<bool> confirmDestructive({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final confirmed = await AppFormModal.show<bool>(
      context: context,
      builder: (dialogContext) => AppFormModal(
        title: title,
        description: message,
        width: AppDialogWidth.sm,
        actions: [
          secondaryAction(
            context: dialogContext,
            label: cancelLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          destructiveFilledAction(
            context: dialogContext,
            label: confirmLabel,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
        children: const [],
      ),
    );
    return confirmed ?? false;
  }

  /// The confirming action of a destructive prompt in a dialog footer.
  static Widget destructiveFilledAction({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) => AppButton(
    onPressed: onPressed,
    variant: AppButtonVariant.destructiveFilled,
    child: Text(label),
  );

  /// An outlined destructive control - a page action, not a dialog confirm.
  static Widget destructiveAction({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) => AppButton(
    onPressed: onPressed,
    variant: AppButtonVariant.destructive,
    child: Text(label),
  );

  /// The confirming action of a non-destructive prompt.
  static Widget primaryAction({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) => AppButton(
    onPressed: onPressed,
    isLoading: isLoading,
    child: Text(label),
  );

  /// The dismissing action. Always sits left of the confirming one.
  static Widget secondaryAction({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) => AppButton(
    onPressed: onPressed,
    variant: AppButtonVariant.outline,
    child: Text(label),
  );

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;

    final badgeGlyph =
        iconWidget ??
        (icon == null
            ? null
            : AppIcon(
                icon!,
                color: iconTone.foreground(context),
                size: context.appMetrics.iconLarge,
              ));

    final titleText = title;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (badgeGlyph != null) ...[
          Center(
            child: Container(
              width: spacing.xxlg,
              height: spacing.xxlg,
              decoration: BoxDecoration(
                color: iconTone.background(context),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: badgeGlyph,
            ),
          ),
          SizedBox(height: spacing.md),
        ],
        if (titleText != null)
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: typography.formTitle.copyWith(color: colors.ink200),
          ),
        if (message != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: typography.body.copyWith(color: colors.mutedForeground),
          ),
        ],
        if (content != null) ...[SizedBox(height: spacing.md), content!],
        SizedBox(height: spacing.lg),
        actions,
      ],
    );

    return AppDialogShell(
      maxWidth: width.value,
      showClose: showClose,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.dialog),
        child: body,
      ),
    );
  }
}

/// A dialog's button row: the actions huddle at the trailing edge at every
/// width - dismiss first, confirm last and flush right.
///
/// A phone footer stays a *row*: stacking two buttons costs a whole extra
/// band of height on the screen that has the least of it. The one exception
/// is a lone action on a narrow slot, which fills the footer on its own
/// rather than floating a small button in a wide empty row.
///
/// Pass the children in reading order - dismiss first, confirm last.
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({required this.children, super.key});

  /// The buttons, dismiss-first.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The footer is measured by its slot, not the window: a 576px panel
        // on a wide screen still wants the compact row, and a full-screen
        // phone page must keep it even if the reporting context above
        // disagrees about the breakpoint.
        final narrow =
            context.formFactor.isCompact || constraints.maxWidth < 480;
        // A lone action on a narrow slot fills the footer; every other row
        // clusters its buttons at the trailing edge.
        if (narrow && children.length == 1) {
          return Row(
            children: [
              Expanded(
                child: SizedBox(width: double.infinity, child: children.single),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) SizedBox(width: spacing.xs),
              child,
            ],
          ],
        );
      },
    );
  }
}

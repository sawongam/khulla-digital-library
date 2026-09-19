// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The chrome every create/edit form is shown in.
///
/// Editing a record is a **modal**, not a destination. A form that owns a
/// route costs a path, a router entry, a back-stack rule and a "where do I
/// return to?" decision at every call site, and it takes the operator off the
/// list they were working through. A modal keeps the list underneath, so
/// adding six titles in a row is six dismissals rather than twelve
/// navigations.
///
/// It adapts rather than branching per platform, and [show] picks the route
/// to match:
///
/// * **Compact** (a phone, a narrow window) - a full-screen page pushed with
///   `fullscreenDialog: true`, so the platform gives it the right transition
///   and the actions sit in a footer above the keyboard inset. A 576px panel
///   floating on a 390px screen is not a dialog, it is a cropped form.
/// * **Anything wider** - a centred panel capped at [width], its body
///   scrolling inside a 90%-viewport cap so the footer never leaves the
///   screen.
///
/// The form's own state lives in the widget passed to [show]; this is chrome
/// only. Pop it with a value to tell the caller what happened -
/// `Navigator.of(context).pop(true)` on save.
class AppFormModal extends StatelessWidget {
  const AppFormModal({
    required this.title,
    required this.children,
    required this.actions,
    this.description,
    this.width = AppDialogWidth.xxl,
    super.key,
  });

  /// The heading, already localized.
  final String title;

  /// The line under the heading - what the form is for, not how to fill it.
  final String? description;

  /// The form's sections, laid out in a stretched column.
  final List<Widget> children;

  /// The footer buttons, dismiss-first. Wrap them in [AppDialogActions].
  final List<Widget> actions;

  /// The panel's width cap on a wide window. Ignored when full-screen.
  final AppDialogWidth width;

  /// Presents [builder]'s form: a full-screen page on a compact window, a
  /// centred panel on anything wider. Resolves to whatever the form pops.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    if (context.formFactor.isCompact) {
      return Navigator.of(context, rootNavigator: true).push<T>(
        MaterialPageRoute<T>(fullscreenDialog: true, builder: builder),
      );
    }
    return showDialog<T>(
      context: context,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final typography = context.appTextStyles;

    final heading = Text(
      title,
      style: typography.displaySmall.copyWith(color: colors.ink200),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) SizedBox(height: spacing.lg),
          child,
        ],
      ],
    );

    final footer = Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.page,
        spacing.xs,
        spacing.page,
        spacing.md,
      ),
      child: AppDialogActions(children: actions),
    );

    if (context.formFactor.isCompact) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.title.copyWith(color: colors.ink200),
          ),
          titleSpacing: spacing.page,
          actions: [
            AppIconButton(
              icon: AppIcons.close,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            SizedBox(width: spacing.xs),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    spacing.page,
                    spacing.md,
                    spacing.page,
                    spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (description != null) ...[
                        Text(
                          description!,
                          style: typography.body.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                        SizedBox(height: spacing.md),
                      ],
                      body,
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: footer,
              ),
            ],
          ),
        ),
      );
    }

    return AppDialogShell(
      maxWidth: width.value,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.lg,
              spacing.lg,
              spacing.lg,
              spacing.sm,
            ),
            child: heading,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                0,
                spacing.lg,
                spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (description case final line?) ...[
                    Text(
                      line,
                      style: typography.body.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                  ],
                  body,
                ],
              ),
            ),
          ),
          footer,
        ],
      ),
    );
  }
}

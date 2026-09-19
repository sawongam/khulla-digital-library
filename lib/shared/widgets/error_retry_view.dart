// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Failure copy with an optional retry action.
///
/// The app-side half of [AppErrorView]: it resolves an [AppException] through
/// [AppExceptionL10n] and the retry label through the ARB files, then hands
/// ready-made strings to the design system. Error strings stay in `l10n`
/// rather than coming from the data layer, and the layout stays in
/// `khulla_ui` rather than being re-implemented per screen.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    this.error,
    this.onRetry,
    this.variant = AppFeedbackVariant.centered,
    this.padding,
  });

  /// The failure to describe. Falls back to the generic message when null.
  final AppException? error;

  /// Called when the retry button is tapped. No button without it.
  final VoidCallback? onRetry;

  /// Layout: centered for a whole screen or section, inline inside a card.
  final AppFeedbackVariant variant;

  /// Overrides the variant's default padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppErrorView(
      message: error?.localizedMessage(l10n) ?? l10n.errorUnknown,
      retryLabel: l10n.commonRetry,
      onRetry: onRetry,
      variant: variant,
      padding: padding,
    );
  }
}

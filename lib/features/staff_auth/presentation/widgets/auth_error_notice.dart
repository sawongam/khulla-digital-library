// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The failure line above an auth form's submit button.
///
/// For the failures a form cannot pin on one field: the catalogue would not
/// open, the write was rejected, the credentials did not match. A field-level
/// problem belongs under its field instead.
///
/// Takes a resolved [message] or an [error] to resolve — the design system
/// deals in strings, so localization happens on this side of the line.
class AuthErrorNotice extends StatelessWidget {
  const AuthErrorNotice({required this.message, super.key}) : error = null;

  /// Renders [exception] through [AppExceptionL10n].
  const AuthErrorNotice.exception(AppException exception, {super.key})
    : error = exception,
      message = null;

  final String? message;
  final AppException? error;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final metrics = context.appMetrics;
    final typography = context.appTextStyles;
    final exception = error;
    final text = message ?? exception!.localizedMessage(context.l10n);

    return AppCard(
      tone: AppStatusTone.danger,
      padding: EdgeInsets.all(spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.error, size: metrics.icon, color: colors.danger),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              text,
              style: typography.body.copyWith(color: colors.ink200),
            ),
          ),
        ],
      ),
    );
  }
}

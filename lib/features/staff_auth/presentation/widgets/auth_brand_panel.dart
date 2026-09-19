// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/widgets/app_logo.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The brand half of the sign-in and onboarding screens.
///
/// It exists to answer the question someone has on their first launch -
/// *what is this, and where does my data go?* - before they type anything.
/// Shown only when the window is wide enough that the form does not need the
/// room; on a phone the same screen leads with the form.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final typography = context.appTextStyles;

    return ColoredBox(
      color: colors.brandDeep,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xlg,
          vertical: spacing.xxlg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLogo.primaryFullLight(height: spacing.xxlg + spacing.xxlg),
                SizedBox(height: spacing.md),
                Text(
                  l10n.authBrandTagline,
                  style: typography.bodyLarge.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: spacing.xlg),
                _AuthBrandPoint(
                  icon: AppIcons.desktop,
                  title: l10n.authBrandLocalTitle,
                  body: l10n.authBrandLocalBody,
                ),
                SizedBox(height: spacing.md),
                _AuthBrandPoint(
                  icon: AppIcons.library,
                  title: l10n.authBrandDeskTitle,
                  body: l10n.authBrandDeskBody,
                ),
                SizedBox(height: spacing.md),
                _AuthBrandPoint(
                  icon: AppIcons.privacy,
                  title: l10n.authBrandOpenTitle,
                  body: l10n.authBrandOpenBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBrandPoint extends StatelessWidget {
  const _AuthBrandPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final AppIconSpec icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final metrics = context.appMetrics;
    final typography = context.appTextStyles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: spacing.xxs),
          child: AppIcon(
            icon,
            size: metrics.icon,
            color: scheme.onPrimary.withValues(alpha: 0.72),
          ),
        ),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: typography.label.copyWith(color: scheme.onPrimary),
              ),
              SizedBox(height: spacing.xxs),
              Text(
                body,
                style: typography.caption.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.64),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

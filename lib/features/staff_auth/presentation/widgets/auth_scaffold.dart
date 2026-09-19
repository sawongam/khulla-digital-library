// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/staff_auth/presentation/widgets/auth_brand_panel.dart';
import 'package:khulla/shared/widgets/app_logo.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The page chrome sign-in and onboarding share.
///
/// Both live **outside** the app shell — there is no rail, no top bar and no
/// section to be in until someone is signed in — so this is the only page
/// frame they get.
///
/// It adapts on one axis. Given room, the window splits: the brand panel
/// explains what Khulla is on the left, the form takes the right. Below
/// [AppFormSection.splitFrom] there is no room for both, and the form gets
/// the whole width with a small mark above it rather than a panel squeezed
/// into a column it cannot fill.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});

  /// The form, already capped by [contentMaxWidth].
  final Widget child;

  /// Widest the form column gets. A sign-in form the width of a monitor is
  /// harder to fill in, not easier.
  static const double contentMaxWidth = 460;

  /// Slot width at or above which the brand panel appears beside the form.
  static const double splitFrom = 1000;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= splitFrom
            ? Row(
                children: [
                  const Expanded(flex: 5, child: AuthBrandPanel()),
                  Expanded(flex: 6, child: _AuthContent(child: child)),
                ],
              )
            : _AuthContent(showMark: true, child: child),
      ),
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent({required this.child, this.showMark = false});

  final Widget child;

  /// Whether to lead with the app mark, for the layout with no brand panel.
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.page,
            vertical: spacing.xlg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthScaffold.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showMark) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogo.primary(height: spacing.lg),
                  ),
                  SizedBox(height: spacing.lg),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

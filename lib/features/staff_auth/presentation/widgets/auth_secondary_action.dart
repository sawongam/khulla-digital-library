// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// Muted caption action below an auth form's primary button.
///
/// Same weight and colour on every auth screen so secondary navigation reads
/// as quiet help, not a second call to action.
class AuthSecondaryAction extends StatelessWidget {
  const AuthSecondaryAction({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTextStyles;

    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: typography.caption.copyWith(color: colors.textMuted),
          ),
        ),
      ),
    );
  }
}

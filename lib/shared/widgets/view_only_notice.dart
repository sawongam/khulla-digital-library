// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Says, once and plainly, that this screen is readable but not writable.
///
/// Most of the app answers a missing permission by removing the control -
/// an *Add title* button a role cannot use is furniture, so it is not drawn.
/// A form is the exception: taking the save button off a page full of filled
/// fields looks like a bug, not a rule. So the fields stay, and this says why
/// they will not budge.
class ViewOnlyNotice extends StatelessWidget {
  const ViewOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.appRadius.control),
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.sm,
        ),
        child: Row(
          children: [
            AppIcon(
              AppIcons.preview,
              size: spacing.md + 2,
              color: colors.textMuted,
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                context.l10n.permissionViewOnlyNotice,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Makes everything under it unreachable when [viewOnly].
///
/// Both halves matter. [AbsorbPointer] stops the pointer, and [ExcludeFocus]
/// stops the keyboard - without it a form that looks inert is still one Tab
/// key away from being typed into.
class ViewOnlyForm extends StatelessWidget {
  const ViewOnlyForm({required this.viewOnly, required this.child, super.key});

  /// Whether the role may look but not touch.
  final bool viewOnly;

  /// The form.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      !viewOnly ? child : ExcludeFocus(child: AbsorbPointer(child: child));
}

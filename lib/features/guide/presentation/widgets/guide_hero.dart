// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The guide's opening panel: what this is, and the search that finds any of
/// it.
///
/// The one place in the product that carries a filled brand surface. It earns
/// it by being the only screen a reader arrives at without a task — every
/// other page in the app opens onto work, and hairlines are what keep those
/// readable.
class GuideHero extends StatelessWidget {
  const GuideHero({
    required this.controller,
    required this.onQueryChanged,
    required this.onStartWalkthrough,
    super.key,
  });

  /// Drives the search field, so the page can clear it.
  final TextEditingController controller;

  /// Called on every keystroke.
  final ValueChanged<String> onQueryChanged;

  /// Opens the getting-started walkthrough, for a reader who would rather
  /// follow steps than browse sections.
  final VoidCallback onStartWalkthrough;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final l10n = context.l10n;
    final compact = context.formFactor.isCompact;

    // The one filled control on the page, sitting on the brand panel it
    // inverts: a first-day reader meets the walkthrough before the catalogue
    // of sections, without it costing the page a whole card of its own.
    final walkthroughButton = AppButton(
      onPressed: onStartWalkthrough,
      trailingIcon: AppIcons.arrowRight,
      // A phone has no room beside the eyebrow for a five-word button, so
      // it drops under the search and stretches instead of overflowing.
      expand: compact,
      child: Text(l10n.guideStartHereAction),
    );

    return Container(
      padding: EdgeInsets.all(compact ? spacing.md : spacing.lg),
      decoration: BoxDecoration(
        color: colors.brandSoft,
        borderRadius: BorderRadius.circular(context.appRadius.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppIcon(
                      AppIcons.openBook,
                      size: 16,
                      color: colors.brandStrong,
                    ),
                    SizedBox(width: spacing.xxs),
                    Flexible(
                      child: Text(
                        l10n.guideHeroEyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.micro.copyWith(
                          color: colors.brandStrong,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                SizedBox(width: spacing.sm),
                walkthroughButton,
              ],
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            l10n.guideHeroTitle,
            style: (compact ? type.displaySmall : type.displayMedium).copyWith(
              color: colors.brandDeep,
            ),
          ),
          SizedBox(height: spacing.xs),
          // ConstrainedBox(
          //   constraints: const BoxConstraints(maxWidth: 560),
          //   child: Text(
          //     l10n.guideHeroBody,
          //     style: type.bodyLarge.copyWith(color: colors.textMuted),
          //   ),
          // ),
          // SizedBox(height: spacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppSearchField(
              controller: controller,
              hintText: l10n.guideSearchHint,
              clearTooltip: l10n.guideSearchClear,
              onChanged: onQueryChanged,
            ),
          ),
          if (compact) ...[
            SizedBox(height: spacing.md),
            walkthroughButton,
          ],
        ],
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_state.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// "Step 1 of 2", with a bar per step.
///
/// A wizard with no visible end is a wizard people abandon, so the count is
/// stated plainly and the bars show how little is left. The number of bars
/// comes from [OnboardingState.stepCount], not from a literal.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({required this.step, super.key});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final motion = context.appMotion;
    final radius = context.appRadius;
    final typography = context.appTextStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingStepCounter(step.position, OnboardingState.stepCount),
          style: typography.micro.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: spacing.xs),
        Row(
          children: [
            for (final value in OnboardingStep.values) ...[
              if (value.index > 0) SizedBox(width: spacing.xxs),
              Expanded(
                child: AnimatedContainer(
                  duration: motion.layout,
                  curve: motion.standard,
                  height: spacing.xxs,
                  decoration: BoxDecoration(
                    color: value.index <= step.index
                        ? colors.brand
                        : colors.muted,
                    borderRadius: BorderRadius.circular(radius.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

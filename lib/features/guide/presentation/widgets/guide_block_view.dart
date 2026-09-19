// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_callout.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_faq_list.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_screen_mock.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_step_list.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_term_list.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Turns one [GuideBlock] into its widget.
///
/// The single place the article's data model meets the design system, which
/// is what lets a new kind of block be added by extending the sealed type and
/// answering the analyzer's complaint here — rather than by hunting for every
/// page that renders content.
class GuideBlockView extends StatelessWidget {
  const GuideBlockView(this.block, {super.key});

  /// The piece of the article to draw.
  final GuideBlock block;

  @override
  Widget build(BuildContext context) => switch (block) {
    final GuideParagraph paragraph => Text(
      paragraph.text,
      style: context.appTextStyles.bodyLarge.copyWith(
        color: context.appColors.textMuted,
      ),
    ),
    final GuideSteps steps => GuideStepList(steps),
    final GuideCallout callout => GuideCalloutView(callout),
    final GuideTerms terms => GuideTermList(terms),
    final GuideFaq faq => GuideFaqList(faq),
    final GuideScreenshot shot => GuideScreenMock(shot),
  };
}

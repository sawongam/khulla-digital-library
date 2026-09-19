// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// An aside with a standing — a tip, a caution, a warning that costs records.
///
/// The tone is the whole point: a page of eight identical grey boxes trains
/// the reader to skip all of them, and the one that said *restoring replaces
/// everything* goes with the rest.
class GuideCalloutView extends StatelessWidget {
  const GuideCalloutView(this.callout, {super.key});

  /// What to say, and how loudly.
  final GuideCallout callout;

  AppIconSpec get _icon => switch (callout.tone) {
    AppStatusTone.danger => AppIcons.warning,
    AppStatusTone.warning => AppIcons.warning,
    AppStatusTone.success => AppIcons.success,
    AppStatusTone.brand => AppIcons.discover,
    AppStatusTone.info || AppStatusTone.neutral => AppIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final ink = callout.tone.foreground(context);

    return AppCard(
      tone: callout.tone,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(_icon, size: context.appMetrics.icon, color: ink),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callout.title,
                  style: type.sectionTitle.copyWith(color: ink),
                ),
                SizedBox(height: spacing.xxs),
                Text(
                  callout.body,
                  style: type.body.copyWith(color: context.appColors.textHigh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

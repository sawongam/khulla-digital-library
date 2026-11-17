// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One settings group as a card: heading and explanation on top, its fields
/// below. Cards are placed side by side by `SettingsSectionColumns`.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;

  /// The fields, in tab order.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.appSpacing.sm,
        children: children,
      ),
    );
  }
}

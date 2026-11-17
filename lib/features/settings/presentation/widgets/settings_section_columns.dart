// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// Lays settings cards out in two independent columns on a wide pane, so a
/// short card does not leave a hole beside a tall one, and stacks them
/// (leading first, then trailing) on a narrow one.
class SettingsSectionColumns extends StatelessWidget {
  const SettingsSectionColumns({
    required this.leading,
    required this.trailing,
    super.key,
  });

  final List<Widget> leading;
  final List<Widget> trailing;

  /// Pane width from which the two columns sit side by side.
  static const double splitFrom = 900;

  @override
  Widget build(BuildContext context) {
    final gap = context.appSpacing.md;

    Widget column(List<Widget> cards) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: cards,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < splitFrom) {
          return column([...leading, ...trailing]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            Expanded(child: column(leading)),
            Expanded(child: column(trailing)),
          ],
        );
      },
    );
  }
}

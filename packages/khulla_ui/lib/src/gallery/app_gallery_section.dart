// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// One labelled block in the design-system gallery.
///
/// The gallery is a development surface, so its own chrome is deliberately
/// plain: a heading, a one-line note about what the reader should be checking,
/// and the specimens. Anything more decorative would compete with the
/// components it exists to show.
class AppGallerySection extends StatelessWidget {
  const AppGallerySection({
    required this.title,
    required this.note,
    required this.children,
    super.key,
  });

  /// The block's name - "Buttons", "Table".
  final String title;

  /// What to look at here, in one line.
  final String note;

  /// The specimens.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.appTextStyles.pageHeader.copyWith(
            color: colors.ink100,
          ),
        ),
        SizedBox(height: spacing.xxs),
        Text(
          note,
          style: context.appTextStyles.body.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        SizedBox(height: spacing.md),
        ...children,
      ],
    );
  }
}

/// A labelled row of specimens that wraps rather than overflowing.
class AppGalleryRow extends StatelessWidget {
  const AppGalleryRow({required this.label, required this.children, super.key});

  /// What this row varies - "variants", "sizes", "states".
  final String label;

  /// The specimens.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.appTextStyles.micro.copyWith(
              color: context.appColors.ink600,
            ),
          ),
          SizedBox(height: spacing.xs),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ],
      ),
    );
  }
}

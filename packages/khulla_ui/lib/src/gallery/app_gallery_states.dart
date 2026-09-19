// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The gallery's states section: loading, empty and error.
///
/// Stateless - the skeleton pulse and the spinners run on their own, and the
/// empty/error actions are no-ops.
class AppGalleryStates extends StatelessWidget {
  const AppGalleryStates({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return AppGalleryStack(
      children: [
        AppGallerySection(
          title: 'Loading',
          note:
              'Two spinners with two jobs, and a skeleton that pulses opacity '
              'rather than sweeping a gradient.',
          children: [
            const AppGalleryRow(
              label: 'spinners',
              children: [
                AppSpinner(size: AppSpinner.buttonSize),
                AppSpinner(),
              ],
            ),
            AppGalleryRow(
              label: 'skeletons',
              children: [
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeleton(width: 200, height: 20),
                      SizedBox(height: spacing.xs),
                      const AppSkeleton(height: 14),
                      SizedBox(height: spacing.xs),
                      const AppSkeleton(width: 240, height: 14),
                    ],
                  ),
                ),
                const AppSkeleton(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                ),
              ],
            ),
          ],
        ),
        const AppGallerySection(
          title: 'Empty',
          note:
              '96px of vertical room, one glyph, an 18px bold heading, one '
              'line of copy, one action.',
          children: [
            AppEmptyView(
              icon: AppIcons.inventory,
              title: 'No copies yet',
              message:
                  'Add the first copy and it will show up here with its '
                  'barcode and shelf location.',
              actionLabel: 'Add copy',
              onAction: _noop,
            ),
          ],
        ),
        const AppGallerySection(
          title: 'Error',
          note: 'A failed read, with the retry beside it.',
          children: [
            AppErrorView(
              message: 'The catalogue could not be opened.',
              retryLabel: 'Try again',
              onRetry: _noop,
            ),
          ],
        ),
      ],
    );
  }
}

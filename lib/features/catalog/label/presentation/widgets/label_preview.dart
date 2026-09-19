// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// What one sticker will look like coming off the printer.
///
/// The barcode is drawn rather than encoded: this screen is about the label's
/// *layout* - what fits at 38 × 21 mm, whether the shelf mark still reads at
/// arm's length - and a real Code 128 rendering answers none of those
/// questions any better than a faithful set of bars does. Encoding belongs to
/// the print pipeline, next to the paper size.
class LabelPreview extends StatelessWidget {
  const LabelPreview({
    required this.barcode,
    required this.width,
    required this.height,
    this.title,
    this.author,
    this.shelf,
    this.libraryName,
    super.key,
  });

  /// The copy's barcode, printed under the bars.
  final String barcode;

  /// The sticker's width in logical pixels.
  final double width;

  /// The sticker's height in logical pixels.
  final double height;

  /// The work's title, when the layout includes it.
  final String? title;

  /// The author, when the layout includes it.
  final String? author;

  /// The shelf mark, when the layout includes it.
  final String? shelf;

  /// The library's name, when the layout includes it.
  final String? libraryName;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final work = title;
    final by = author;
    final mark = shelf;
    final library = libraryName;

    // A fixed pattern rather than a random one: a preview that reshuffles on
    // every rebuild reads as a loading state.
    const widths = <double>[
      2,
      1,
      3,
      1,
      1,
      2,
      4,
      1,
      2,
      1,
      3,
      2,
      1,
      4,
      1,
      2,
      3,
      1,
    ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.appRadius.item),
        border: Border.all(color: colors.hairlineStrong),
      ),
      padding: EdgeInsets.all(spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (library != null)
            Text(
              library,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: colors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          if (work != null)
            Text(
              work,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: colors.textHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (by != null)
            Text(
              by,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: colors.textMuted,
              ),
            ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in widths)
                Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: Container(
                    width: bar,
                    height: height * 0.24,
                    color: colors.textHigh,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: colors.textHigh,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (mark != null)
                Text(
                  mark,
                  maxLines: 1,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

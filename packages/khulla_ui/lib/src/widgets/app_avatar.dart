// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The initials tile standing in for a person or a record.
///
/// A rounded square, not a circle, and neutral by default. A column of
/// tinted circles down the left of a list reads as status - which is what
/// tint means everywhere else in this app - so the avatar stays quiet and
/// leaves color to the badge beside it.
///
/// It takes the initials rather than a name: deriving them is a locale
/// question - a Nepali name does not split the way an English one does - and
/// that belongs to the feature that owns the record, not to the design system.
///
/// [tone] exists for the rare avatar that genuinely carries standing - a
/// suspended member. Do not vary it per record to make a list colorful.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.initials,
    this.size = 40,
    this.tone = AppStatusTone.neutral,
    this.badge,
    this.badgeTone = AppStatusTone.success,
    super.key,
  });

  /// One or two characters, already cased.
  final String initials;

  /// The tile's edge length.
  final double size;

  /// Which wash and ink to paint.
  final AppStatusTone tone;

  /// A glyph pinned to the bottom-trailing edge - a verified check, a
  /// suspended block. Null draws no badge.
  final AppIconSpec? badge;

  /// The badge's tone.
  final AppStatusTone badgeTone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final glyph = badge;

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.background(context),
        borderRadius: BorderRadius.circular(context.appRadius.control),
        border: Border.all(color: tone.border(context)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        maxLines: 1,
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: size * 0.36,
          height: 1,
          color: tone.foreground(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (glyph == null) return tile;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                glyph,
                size: size * 0.36,
                color: badgeTone.foreground(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_segmented_control}
/// A small set of mutually exclusive choices, all visible at once - *All /
/// On loan / Overdue*, or a list/grid view switch.
///
/// A brand pill on a grey track: the track is the secondary surface with a
/// hairline, the items sit at the item radius inside it, and the active one
/// is a filled brand chip. Deliberately not Material's outlined segmented
/// button, whose per-segment borders read as four buttons rather than one
/// control.
///
/// Use it up to about four choices where the options matter enough to stay on
/// screen. Past that, or where the set is data-driven, use
/// [AppDropdownField].
/// {@endtemplate}
class AppSegmentedControl<T> extends StatelessWidget {
  /// {@macro app_segmented_control}
  const AppSegmentedControl({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.itemIcon,
    this.showSelectedIcon = false,
    this.expand = false,
    super.key,
  });

  /// The active choice.
  final T value;

  /// The choices, in display order.
  final List<T> items;

  /// Turns a choice into its localized label.
  final String Function(T value) itemLabel;

  /// Called with the new choice.
  final ValueChanged<T> onChanged;

  /// Optional per-choice glyph.
  final AppIconSpec? Function(T value)? itemIcon;

  /// Whether the selected segment shows a check mark. Off by default: the
  /// fill already says which one is active, and the tick costs width.
  final bool showSelectedIcon;

  /// Whether each segment shares the track width equally. Use in a form column
  /// so the control lines up with a neighbouring field.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      width: expand ? double.infinity : null,
      padding: EdgeInsets.all(spacing.xxs),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(radius.container),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final item in items)
            if (expand)
              Expanded(
                child: _Segment(
                  label: itemLabel(item),
                  icon: itemIcon?.call(item),
                  selected: item == value,
                  showSelectedIcon: showSelectedIcon,
                  expand: true,
                  onTap: () => onChanged(item),
                ),
              )
            else
              _Segment(
                label: itemLabel(item),
                icon: itemIcon?.call(item),
                selected: item == value,
                showSelectedIcon: showSelectedIcon,
                onTap: () => onChanged(item),
              ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.showSelectedIcon,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final AppIconSpec? icon;
  final bool selected;
  final bool showSelectedIcon;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(context.appRadius.item);
    final foreground = selected ? scheme.onPrimary : colors.ink400;
    final glyph = selected && showSelectedIcon ? AppIcons.check : icon;

    return AppRipple(
      onTap: onTap,
      borderRadius: radius,
      pressScale: 1,
      child: AnimatedContainer(
        duration: context.appMotion.color,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: radius,
          boxShadow: selected ? context.appShadows.card : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: expand
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (glyph != null) ...[
              AppIcon(
                glyph,
                size: context.appMetrics.iconInButton,
                color: foreground,
              ),
              SizedBox(width: spacing.xs - 2),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: expand ? TextAlign.center : TextAlign.start,
                style: context.appTextStyles.label.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

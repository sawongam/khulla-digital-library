// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_menu_button}
/// The overflow menu: an icon button that opens a list of [AppMenuAction]s.
/// {@endtemplate}
class AppMenuButton extends StatelessWidget {
  /// {@macro app_menu_button}
  const AppMenuButton({
    required this.actions,
    required this.tooltip,
    this.icon = AppIcons.more,
    super.key,
  });

  /// The entries, in order, destructive ones last.
  final List<AppMenuAction> actions;

  /// What the menu holds, already localized - "More actions".
  final String tooltip;

  /// The trigger glyph.
  final AppIconSpec icon;

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<AppMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height,
        overlay.size.width - origin.dx - box.size.width,
        overlay.size.height - origin.dy - box.size.height,
      ),
      items: [
        for (final action in actions)
          PopupMenuItem<AppMenuAction>(
            value: action,
            enabled: action.enabled,
            height: 0,
            padding: EdgeInsets.symmetric(
              horizontal: context.appSpacing.xs,
              vertical: context.appSpacing.xs + 2,
            ),
            mouseCursor: action.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: _MenuActionRow(action: action),
          ),
      ],
    );
    selected?.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      tooltip: tooltip,
      size: AppIconButtonSize.small,
      onPressed: () => _openMenu(context),
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  const _MenuActionRow({required this.action});

  final AppMenuAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = action.isDestructive ? colors.danger : colors.ink200;
    final glyph = action.icon;

    return Row(
      children: [
        if (glyph != null) ...[
          AppIcon(glyph, size: context.appMetrics.icon, color: foreground),
          SizedBox(width: context.appSpacing.menuIconGap),
        ],
        Text(
          action.label,
          style: context.appTextStyles.label.copyWith(color: foreground),
        ),
      ],
    );
  }
}

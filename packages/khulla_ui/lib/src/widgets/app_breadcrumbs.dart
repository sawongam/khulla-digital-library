// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// One step in a breadcrumb trail.
class AppBreadcrumb {
  const AppBreadcrumb({required this.label, this.onTap});

  /// The step's name, already localized.
  final String label;

  /// Where the step goes. The last crumb is the current page and carries no
  /// callback - a breadcrumb that navigates to where you already are is a
  /// dead control that looks live.
  final VoidCallback? onTap;
}

/// The trail above a page title: *Dashboard / Members / Livia Hart*.
class AppBreadcrumbs extends StatelessWidget {
  const AppBreadcrumbs({required this.crumbs, super.key});

  /// The trail, root first, current page last.
  final List<AppBreadcrumb> crumbs;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final style = context.textTheme.bodySmall;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (index, crumb) in crumbs.indexed) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppIcon(
                AppIcons.chevronRight,
                size: 14,
                color: colors.textMuted,
              ),
            ),
          if (crumb.onTap == null)
            Text(
              crumb.label,
              style: style?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            _CrumbLink(crumb: crumb, color: scheme.primary, style: style),
        ],
      ],
    );
  }
}

class _CrumbLink extends StatefulWidget {
  const _CrumbLink({
    required this.crumb,
    required this.color,
    required this.style,
  });

  final AppBreadcrumb crumb;
  final Color color;
  final TextStyle? style;

  @override
  State<_CrumbLink> createState() => _CrumbLinkState();
}

class _CrumbLinkState extends State<_CrumbLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.crumb.onTap,
        child: Text(
          widget.crumb.label,
          style: widget.style?.copyWith(
            color: widget.color,
            fontWeight: FontWeight.w500,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: widget.color,
          ),
        ),
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The search input above a collection, and the global one in the top bar.
///
/// It does **not** debounce. The cubit owns that, because only the cubit
/// knows whether the query costs a `LIKE` over ten thousand rows or a filter
/// over a list already in memory.
///
/// It carries the same hairline box as every other field - no fill, no focus
/// ring, and the same 2px focus nudge - so a search bar above a table and a
/// text field inside a form read as the same control. A leading glyph in the
/// muted icon ink is the only thing that marks it as search.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.clearTooltip,
    this.onSubmitted,
    this.focusNode,
    this.trailing,
    this.autofocus = false,
    this.enabled = true,
    this.dense = false,
    super.key,
  });

  /// Placeholder copy - say what is searched, not "Search".
  final String hintText;

  /// Called on every keystroke.
  final ValueChanged<String> onChanged;

  /// Supply one to drive the field from outside; otherwise it owns its own.
  final TextEditingController? controller;

  /// Tooltip for the clear button. Null hides the button entirely.
  final String? clearTooltip;

  /// Called when the user commits the query.
  final ValueChanged<String>? onSubmitted;

  /// External focus, for a screen that focuses search on open.
  final FocusNode? focusNode;

  /// A control pinned inside the trailing edge - a scope switch, a filter
  /// glyph. Replaced by the clear button while the field has text.
  final Widget? trailing;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Whether the field accepts input.
  final bool enabled;

  /// Tightens the field to sit inside a toolbar row.
  final bool dense;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _ownedController;
  late TextEditingController _controller = _resolveController();

  TextEditingController _resolveController() {
    final supplied = widget.controller;
    if (supplied != null) return supplied;
    return _ownedController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _ownedController?.dispose();
      _ownedController = null;
      _controller = _resolveController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final metrics = context.appMetrics;
    final clearLabel = widget.clearTooltip;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: context.appTextStyles.body.copyWith(color: scheme.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          prefixIcon: AppFieldAffix(
            child: AppIcon(
              AppIcons.search,
              size: metrics.icon,
              color: colors.mutedForeground,
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: metrics.fieldHeight,
            minHeight: metrics.fieldHeight,
          ),
          suffixIcon: switch ((value.text.isNotEmpty, clearLabel)) {
            (true, final label?) => AppFieldAffix(
              child: AppIconButton(
                icon: AppIcons.close,
                tooltip: label,
                size: AppIconButtonSize.small,
                onPressed: _clear,
              ),
            ),
            _ => switch (widget.trailing) {
              final trailing? => AppFieldAffix(child: trailing),
              _ => null,
            },
          },
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.sm,
            vertical: widget.dense ? spacing.xs : spacing.sm,
          ),
        ),
      ),
    );
  }
}

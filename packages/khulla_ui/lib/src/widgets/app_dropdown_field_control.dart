// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// How many choices a menu may carry before it grows a search header.
const int kAppDropdownSearchThreshold = 8;

/// Visible rows in a scrollable menu before the list scrolls.
const int kAppDropdownVisibleRows = 5;

/// The overlay-anchored control behind [AppDropdownField]: the tappable
/// field, keyboard handling, and the menu lifecycle.
///
/// Split from the labelled facade so the field chrome and the overlay logic
/// can be read - and tested - independently.
class AppDropdownFieldControl<T> extends StatefulWidget {
  const AppDropdownFieldControl({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.itemIcon,
    this.searchable,
    this.searchHint,
    this.clearSearchTooltip,
    this.emptySearchMessage,
    this.searchThreshold = kAppDropdownSearchThreshold,
    this.itemMatchesSearch,
    this.menuMaxHeight,
    this.footerActionLabel,
    this.onFooterAction,
    this.footerActionIcon,
    super.key,
  });

  final T? value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final bool enabled;
  final AppIconSpec? Function(T value)? itemIcon;
  final bool? searchable;
  final String? searchHint;
  final String? clearSearchTooltip;
  final String? emptySearchMessage;
  final int searchThreshold;
  final bool Function(T item, String query)? itemMatchesSearch;
  final double? menuMaxHeight;
  final String? footerActionLabel;
  final VoidCallback? onFooterAction;
  final AppIconSpec? footerActionIcon;

  @override
  State<AppDropdownFieldControl<T>> createState() =>
      _AppDropdownFieldControlState<T>();
}

class _AppDropdownFieldControlState<T>
    extends State<AppDropdownFieldControl<T>> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _fieldFocus = FocusNode();
  OverlayEntry? _overlay;
  ScrollController? _scrollController;
  String _query = '';
  double _fieldWidth = 0;

  bool get _isSearchable =>
      widget.searchable ?? widget.items.length > widget.searchThreshold;

  double _itemExtent(BuildContext context) =>
      context.appMetrics.fieldHeight - 4;

  double _menuMaxHeight(BuildContext context) =>
      widget.menuMaxHeight ?? _itemExtent(context) * kAppDropdownVisibleRows;

  List<T> get _filteredItems {
    if (!_isSearchable || _query.trim().isEmpty) return widget.items;

    final needle = _query.trim().toLowerCase();
    final matches = widget.itemMatchesSearch;
    if (matches != null) {
      return widget.items.where((item) => matches(item, needle)).toList();
    }

    return widget.items
        .where(
          (item) => widget.itemLabel(item).toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  void dispose() {
    _closeMenu();
    _searchController.dispose();
    _searchFocus.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_overlay != null) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _query = '';
    _searchController.clear();
    _scrollController?.dispose();
    _scrollController = ScrollController(
      initialScrollOffset: _initialScrollOffset(),
    );

    _overlay = OverlayEntry(
      builder: (overlayContext) => AppDropdownMenu<T>(
        layerLink: _layerLink,
        fieldWidth: _fieldWidth,
        searchFocus: _searchFocus,
        searchController: _searchController,
        scrollController: _scrollController!,
        searchable: _isSearchable,
        searchHint: widget.searchHint,
        clearSearchTooltip: widget.clearSearchTooltip,
        emptySearchMessage: widget.emptySearchMessage,
        items: _filteredItems,
        selected: widget.value,
        itemLabel: widget.itemLabel,
        itemIcon: widget.itemIcon,
        itemExtent: _itemExtent(overlayContext),
        menuMaxHeight: _menuMaxHeight(overlayContext),
        enabled: widget.enabled,
        footerActionLabel: widget.footerActionLabel,
        onFooterAction: widget.onFooterAction,
        footerActionIcon: widget.footerActionIcon,
        onQueryChanged: (query) {
          _query = query;
          _scrollController?.jumpTo(0);
          _overlay?.markNeedsBuild();
        },
        onSelected: (item) {
          widget.onChanged(item);
          _closeMenu();
        },
        onClose: _closeMenu,
      ),
    );

    Overlay.of(context).insert(_overlay!);

    if (_isSearchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlay != null) _searchFocus.requestFocus();
      });
    }
  }

  double _initialScrollOffset() {
    final selected = widget.value;
    if (selected == null) return 0;

    final index = widget.items.indexOf(selected);
    if (index <= 0) return 0;

    final extent = _itemExtent(context);
    return ((index - 2) * extent).clamp(0.0, double.infinity);
  }

  void _closeMenu() {
    _overlay?.remove();
    _overlay = null;
    _scrollController?.dispose();
    _scrollController = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final metrics = context.appMetrics;
    final typography = context.appTextStyles;
    final iconFor = widget.itemIcon;
    final selected = widget.value;
    final hasValue = selected != null;
    final selectedIcon = hasValue ? iconFor?.call(selected) : null;
    final enabled = widget.enabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        _fieldWidth = constraints.maxWidth;

        return CompositedTransformTarget(
          link: _layerLink,
          child: Focus(
            focusNode: _fieldFocus,
            onKeyEvent: (node, event) {
              if (!enabled) return KeyEventResult.ignored;
              if (event is! KeyDownEvent) return KeyEventResult.ignored;

              if (event.logicalKey == LogicalKeyboardKey.escape) {
                if (_overlay != null) {
                  _closeMenu();
                  return KeyEventResult.handled;
                }
              }

              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                _toggleMenu();
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: MouseRegion(
              cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? _toggleMenu : null,
                // Content-sized, same as [AppTextField]: forcing [fieldHeight]
                // with `expands` stretches the outline past a neighbouring
                // text field.
                child: InputDecorator(
                  isEmpty: !hasValue,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hintText,
                    enabled: enabled,
                    contentPadding: EdgeInsetsDirectional.only(
                      start: spacing.sm,
                      end: spacing.sm,
                      top: spacing.xs,
                      bottom: spacing.xs,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectedIcon != null) ...[
                        AppIcon(
                          selectedIcon,
                          size: metrics.icon,
                          color: colors.ink500,
                        ),
                        SizedBox(width: spacing.menuIconGap),
                      ],
                      Expanded(
                        child: hasValue
                            ? Text(
                                widget.itemLabel(selected),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.body.copyWith(
                                  color: enabled
                                      ? colors.ink100
                                      : colors.ink500,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AppIcon(
                        AppIcons.chevronDown,
                        size: metrics.icon,
                        color: colors.ink500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

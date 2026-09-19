// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_dropdown_field}
/// A labelled select, decorated to match [AppTextField] so a form of mixed
/// controls lines up.
///
/// Generic over the value so a caller keeps its own enum or domain type all
/// the way to `onChanged` - no string round trip, no parsing back. [itemLabel]
/// is how a value becomes text, which keeps localization on the app side.
///
/// Long lists open in a capped panel: a fixed search header when
/// [searchable] is true or once [items] exceeds [searchThreshold], then a
/// scrollable list underneath. Short lists skip search and still cap height
/// when they would overflow [menuMaxHeight]. Overflowing lists keep a
/// scrollbar thumb visible so the extra rows are obvious without dragging.
///
/// [footerActionLabel] pins a create action under the list - the caller
/// supplies the copy and what happens; this widget only closes the menu and
/// fires [onFooterAction].
/// {@endtemplate}
class AppDropdownField<T> extends StatelessWidget {
  /// {@macro app_dropdown_field}
  const AppDropdownField({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.label,
    this.hintText,
    this.errorText,
    this.required = false,
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
  }) : assert(
         searchable != true || searchHint != null,
         'searchHint is required when searchable is true',
       ),
       assert(
         (footerActionLabel == null) == (onFooterAction == null),
         'footerActionLabel and onFooterAction must be set together',
       );

  /// The current selection. Null shows [hintText].
  final T? value;

  /// The choices, in display order.
  final List<T> items;

  /// Turns a choice into its localized label.
  final String Function(T value) itemLabel;

  /// Called when a choice is made.
  final ValueChanged<T?> onChanged;

  /// Label shown above the control.
  final String? label;

  /// Placeholder while nothing is selected.
  ///
  /// Defaults to [label] when omitted so labelled fields always show a hint.
  final String? hintText;

  /// Validation message shown under the control.
  final String? errorText;

  /// When true, the label shows a required asterisk.
  final bool required;

  /// Whether the control accepts input.
  final bool enabled;

  /// Optional per-choice glyph - a status dot, a format icon.
  final AppIconSpec? Function(T value)? itemIcon;

  /// Whether the menu carries a fixed search header. Defaults to true once
  /// [items] exceeds [searchThreshold].
  final bool? searchable;

  /// Placeholder in the menu search field. Required when [searchable] is true.
  final String? searchHint;

  /// Tooltip on the search clear button.
  final String? clearSearchTooltip;

  /// Shown when search filters every item out.
  final String? emptySearchMessage;

  /// Item count above which search is offered automatically.
  final int searchThreshold;

  /// Custom filter for search. `query` is lowercased and trimmed.
  ///
  /// Defaults to a case-insensitive match on the label callback.
  final bool Function(T item, String query)? itemMatchesSearch;

  /// Cap on the scrollable list height inside the menu.
  final double? menuMaxHeight;

  /// Label on the pinned action under the list, e.g. "Add format".
  final String? footerActionLabel;

  /// Called after the menu closes when the footer action is pressed.
  final VoidCallback? onFooterAction;

  /// Glyph on the footer action. Defaults to [AppIcons.add].
  final AppIconSpec? footerActionIcon;

  @override
  Widget build(BuildContext context) {
    final metrics = context.appMetrics;
    final fieldLabel = label;
    final hint = hintText ?? fieldLabel;
    final error = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fieldLabel != null) ...[
          AppFieldLabel(
            label: fieldLabel,
            required: required,
            hasError: error != null,
          ),
          SizedBox(height: metrics.labelToControlGap),
        ],
        AppDropdownFieldControl<T>(
          value: value,
          items: items,
          itemLabel: itemLabel,
          onChanged: onChanged,
          hintText: hint,
          enabled: enabled,
          itemIcon: itemIcon,
          searchable: searchable,
          searchHint: searchHint,
          clearSearchTooltip: clearSearchTooltip,
          emptySearchMessage: emptySearchMessage,
          searchThreshold: searchThreshold,
          itemMatchesSearch: itemMatchesSearch,
          menuMaxHeight: menuMaxHeight,
          footerActionLabel: footerActionLabel,
          onFooterAction: onFooterAction,
          footerActionIcon: footerActionIcon,
        ),
        if (error != null) ...[
          SizedBox(height: context.appSpacing.xxs + 2),
          AppFieldError(message: error),
        ],
      ],
    );
  }
}

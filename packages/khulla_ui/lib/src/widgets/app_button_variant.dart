// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

/// What a button *means*, which decides all of its color.
///
/// The set is deliberately small and each entry has one job. If a screen
/// needs a look that is not here, the answer is almost always that it is
/// reaching for the wrong emphasis, not that the system is missing a variant.
enum AppButtonVariant {
  /// The one action a screen is built around. Filled brand.
  primary,

  /// An outlined destructive control on a page (e.g. a header Delete).
  /// Dialog confirms use the filled destructive variant instead.
  destructive,

  /// The confirming action on a destructive prompt and form-modal footers.
  /// Filled like [primary] but in the danger color.
  destructiveFilled,

  /// The neutral action next to a primary one: Cancel, Back, a filter.
  outline,

  /// A quiet filled action on a grey surface - a toolbar's second control.
  secondary,

  /// Chrome-level actions with no surface of their own: a row's menu
  /// trigger, "Clear filters", a card's "View all".
  ghost,

  /// A confirming action that is not the page's primary - "Mark returned".
  success,

  /// A positive secondary action drawn as an outline - "Add a copy".
  successOutline,

  /// Inline navigation inside a sentence. Reads as a link, not a control.
  link,
}

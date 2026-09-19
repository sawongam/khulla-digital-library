// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

/// How much room the UI gives itself.
///
/// This is the *only* density axis in the design system, and it is not a
/// layout axis: nothing reflows when it changes. One step up in type size,
/// control height, icon size and gap - a 1600px monitor gets a 14px body,
/// 44px fields and 48px table headers where a laptop gets 12/40/40. Layout
/// decisions belong to `FormFactor` instead.
///
/// Phones and tablets are always [compact]. Reading it anywhere but the
/// theme builder is what makes the steps desynchronise, so components take
/// resolved numbers from `AppMetrics` rather than asking for the density.
enum AppDensity {
  /// The base rung: 12px body, 40px fields, 36px buttons.
  compact,

  /// One step roomier, from 1600px up: 14px body, 44px fields.
  comfortable;

  /// Whether this is the roomier rung.
  bool get isComfortable => this == AppDensity.comfortable;

  /// Picks the value for this rung. Every paired token resolves through here.
  T pick<T>(T base, T wide) => this == AppDensity.compact ? base : wide;
}

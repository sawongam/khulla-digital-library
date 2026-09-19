// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Fetch lifecycle for a screen backed by a database read.
///
/// One enum for the whole app. Per-feature copies start out byte-identical and
/// then let their `isLoading` semantics drift apart, which is how one screen
/// ends up flashing an empty state that its neighbour does not.
enum LoadStatus { initial, loading, loaded, failure }

/// The vocabulary every state exposes, so a reader moving between features can
/// trust the getters to mean the same thing.
extension LoadStatusX on LoadStatus {
  /// True before the first query runs as well as during it.
  ///
  /// `initial` counts as loading on purpose: a screen that has not read yet
  /// has nothing to show, and treating it as "loaded and empty" flashes an
  /// empty state in the moment before the query is even fired.
  bool get isLoading =>
      this == LoadStatus.initial || this == LoadStatus.loading;

  /// True when the read failed and the state carries an `AppException`.
  bool get hasError => this == LoadStatus.failure;

  /// True once a read has completed successfully.
  bool get isLoaded => this == LoadStatus.loaded;

  /// Status to emit when a filtered collection starts a fetch.
  ///
  /// Keeps [loaded] during refetches so the table does not flash to a spinner
  /// when search, filters, sort or page change. Only the first fetch and a
  /// retry after failure move to [loading].
  LoadStatus forCollectionFetch() => switch (this) {
    LoadStatus.initial || LoadStatus.failure => LoadStatus.loading,
    LoadStatus.loading || LoadStatus.loaded => this,
  };
}

# ADR 0027 - Sliver-based scrolling

**Status:** Accepted · **Date:** 2026-09-03

## Context

A library catalogue page needs to combine several scrolling sections: a filter bar, a results count, a grid of book covers, and possibly a "load more" indicator at the bottom. The natural impulse is to wrap them in a `Column` inside a `SingleChildScrollView`, or to nest a `ListView` inside a parent scroll view using `shrinkWrap: true` + `NeverScrollableScrollPhysics()`. Both work in a demo. Both break on a real catalogue.

### The `shrinkWrap` problem

`shrinkWrap: true` forces a `ListView` or `GridView` to lay out every child upfront so it can report its total height to the parent. On a catalogue of ten thousand titles, this means ten thousand item widgets are built and laid out before the first frame - regardless of how many are visible. Flutter's lazy list building (the entire reason `ListView.builder` exists) is defeated. The result is a screen that takes seconds to open and janks on every scroll because the full layout cost was paid upfront and must be paid again on every rebuild.

`NeverScrollableScrollPhysics()` compounds the problem: it disables the inner list's own scroll, delegating all scroll events to the outer `SingleChildScrollView`. The outer scroll view must now track the combined height of all sections including the fully-laid-out list. On a wide screen with two columns and five thousand titles, this is tens of thousands of pixels of layout state held in memory at all times.

The performance failure is not hypothetical. A school library with 3,000 titles opening the catalog page on a mid-range Windows machine will see this. A community library with 8,000 titles opening it on a Chromebook will hang.

### The one legitimate `shrinkWrap` case

A short, bounded list inside a fixed-height container where the child count is small and known at build time - an autocomplete dropdown with at most ten results, a "recently returned" shelf with five items - is fine with `shrinkWrap: true`. The cost is bounded: five items laid out unconditionally is not a performance concern. The rule is "small and known", not "could be any length."

### Slivers

`CustomScrollView` with slivers is the correct model for any scroll view that combines multiple sections where at least one section is an arbitrarily-long list. Each section is a sliver. Slivers lay out lazily: only the items near the viewport are built and painted. A `SliverList` of ten thousand items builds only the items that are visible plus a small buffer. Adding a filter bar above the list is a `SliverToBoxAdapter` wrapping a normal widget - it does not affect the list's lazy building.

## Decision

Use **`CustomScrollView` with slivers** for any scrollable page that combines multiple sections or contains a list of unbounded length. Never use `shrinkWrap: true` + `NeverScrollableScrollPhysics()` to nest a list inside a parent scroll view.

### Sliver composition pattern

```dart
CustomScrollView(
  slivers: [
    // A normal widget in the scroll view - wraps anything that is not itself a sliver
    SliverToBoxAdapter(
      child: CatalogFilterBar(
        activeFilters: state.filters,
        onFilterChanged: cubit.filterChanged,
      ),
    ),

    // A count / header row
    SliverToBoxAdapter(
      child: Padding(
        padding: context.appSpacing.insetMd,
        child: Text(context.l10n.titleCount(state.titles.length)),
      ),
    ),

    // The main list - lazy, builds only visible items
    SliverList.builder(
      itemCount: state.titles.length,
      itemBuilder: (context, index) => TitleListTile(title: state.titles[index]),
    ),

    // A grid variant - same model
    // SliverGrid.builder(
    //   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    //     maxCrossAxisExtent: 200,
    //     childAspectRatio: 0.7,
    //   ),
    //   itemCount: state.titles.length,
    //   itemBuilder: (context, index) => TitleCoverCard(title: state.titles[index]),
    // ),

    // A footer - loading indicator, end-of-results message, etc.
    SliverToBoxAdapter(
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const SliverPadding(padding: EdgeInsets.zero),
    ),

    // Bottom safe area - so content is not hidden behind the nav bar
    const SliverSafeArea(sliver: SliverToBoxAdapter(child: SizedBox())),
  ],
)
```

### Pinned headers with `SliverPersistentHeader` or `SliverAppBar`

A filter bar or section header that should stick to the top as the user scrolls uses `SliverPersistentHeader(pinned: true, …)` or `SliverAppBar(pinned: true, …)`. The `AppTopBar` is outside the `CustomScrollView` entirely (rendered by the shell), so it is always pinned without any sliver involvement. A per-page sticky sub-header lives inside the `CustomScrollView` as a pinned sliver.

### `SliverPadding` for consistent insets

Rather than wrapping a `SliverList` in a `SliverToBoxAdapter` + `Padding`:

```dart
// Wrong - forces the list into a box, re-introduces the shrinkWrap problem
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ListView.builder(…),  // ← now needs shrinkWrap: true
  ),
),

// Correct - padding applied at the sliver level, list stays lazy
SliverPadding(
  padding: context.appSpacing.insetPageHorizontal,
  sliver: SliverList.builder(
    itemCount: state.titles.length,
    itemBuilder: (context, index) => TitleListTile(title: state.titles[index]),
  ),
),
```

### Empty and loading states inside a `CustomScrollView`

Empty and loading states are normal box widgets wrapped in `SliverFillRemaining`:

```dart
if (state.isLoading)
  const SliverFillRemaining(
    child: Center(child: CircularProgressIndicator()),
  )
else if (state.isEmpty)
  SliverFillRemaining(
    child: EmptyResultView(
      label: context.l10n.noTitlesFound,
      onRetry: cubit.loadTitles,
    ),
  )
else
  SliverList.builder(
    itemCount: state.titles.length,
    itemBuilder: (context, index) => TitleListTile(title: state.titles[index]),
  ),
```

`SliverFillRemaining` expands to fill the remaining viewport height - useful for centered empty/loading states that should not collapse to zero height.

### `CustomScrollView` vs `ListView` / `GridView`

For a page with a single list and no other scrolling sections, a plain `ListView.builder` is fine. The sliver composition pattern is warranted when there are two or more sections, or when a sticky header is needed. The rule is: if you find yourself writing `shrinkWrap: true`, stop and use `CustomScrollView` with slivers instead.

## Consequences

**What this buys**

- A catalogue page with 10,000 titles opens in one frame. Only the visible items are built; scroll performance is smooth regardless of list length.
- Sections above and below the list (filter bar, footer, loading indicator) do not force the list to lay out all items.
- Sticky headers, parallax app bars, and other scroll-linked effects are composable with the same model - add a sliver, no scroll controller gymnastics.
- `SliverFillRemaining` gives empty and loading states the right amount of space without manual height calculations.

**What this costs**

- `SliverToBoxAdapter` is more verbose than putting a widget directly in a `Column`. The naming is not intuitive for developers coming from web or iOS layouts.
- `CustomScrollView` + slivers is a Flutter-specific model. Contributors who have not worked with it before need to learn three or four sliver types before they are comfortable. The learning curve is real but the ceiling is low - `SliverList`, `SliverGrid`, `SliverToBoxAdapter`, `SliverPadding`, and `SliverFillRemaining` cover 90% of cases.
- Mixing slivers and box widgets requires `SliverToBoxAdapter`. Forgetting the wrapper produces a runtime type error (`A non-sliver widget was used where a sliver was expected`) that is clear but only appears at runtime, not at analysis time.

## Revisiting

The trigger to reconsider is a Flutter improvement to `ListView`/`GridView` that makes `shrinkWrap` lazy (a long-standing request that has been explicitly rejected by the Flutter team as architecturally incompatible with how `shrinkWrap` works). Until that changes, `CustomScrollView` with slivers is the correct model for any multi-section or large-list page, and `shrinkWrap` in a list of potentially unbounded length is a bug, not a shortcut.

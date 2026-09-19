# ADR 0012 - `DisposeBag` and widget lifecycle management

**Status:** Accepted · **Date:** 2026-09-03

## Context

A `StatefulWidget` that owns a `TextEditingController` or `FocusNode` must dispose of it in `dispose()`. This is Flutter's contract: controllers and focus nodes register listeners against the engine; failing to dispose them leaks memory and produces `"A TextEditingController was garbage collected while still attached to listeners"` warnings in debug mode.

The standard pattern is:

```dart
class _TitleFormState extends State<TitleForm> {
  late final TextEditingController _titleController;
  late final FocusNode _isbnFocus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _isbnFocus = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnFocus.dispose();
    super.dispose();
  }
}
```

This is correct but fragile in a specific way: adding a fourth controller requires changes in three places - the field declaration, `initState`, and `dispose`. A controller added in one place and forgotten in another compiles and runs, leaking silently. On a form with eight fields the `dispose` method becomes a list that is always one entry behind.

Two alternatives were evaluated:

**`AutomaticKeepAliveClientMixin` + teardown hook.** Flutter has no general "run on dispose" hook built into `State`. The mixin only preserves state across tab switches; it does not help with disposal.

**A bag that tracks created resources and disposes them all at once.** A mixin that overrides `dispose()`, collects every controller and focus node that was created through it, and disposes all of them in a single `super.dispose()` call. Adding a field requires one line, not three. Forgetting `dispose` is structurally impossible - the bag disposes everything it created.

## Decision

Every `StatefulWidget` that owns controllers or focus nodes mixes in **`DisposeBag`** (`lib/core/lifecycle/dispose_bag.dart`) and creates resources through its factory methods. `initState` and `dispose` are not overridden.

```dart
class _TitleFormState extends State<TitleForm> with DisposeBag {
  late final _titleController = textController();
  late final _isbnFocus       = focusNode();
  late final _isbnController  = textController(text: widget.initialIsbn);
}
```

That is the complete lifecycle management for three resources. No `initState`. No `dispose`. No list to keep in sync.

### `DisposeBag` API

```dart
// lib/core/lifecycle/dispose_bag.dart
mixin DisposeBag<T extends StatefulWidget> on State<T> {
  final _disposables = <dynamic>[];

  /// Creates and registers a [TextEditingController].
  /// Pass [text] to set an initial value.
  TextEditingController textController({String? text}) {
    final c = text != null
        ? TextEditingController(text: text)
        : TextEditingController();
    _disposables.add(c);
    return c;
  }

  /// Creates and registers a [FocusNode].
  FocusNode focusNode() {
    final n = FocusNode();
    _disposables.add(n);
    return n;
  }

  /// Registers any [ChangeNotifier] for disposal.
  /// Use for custom notifiers not covered by the typed factories.
  N addDisposable<N extends ChangeNotifier>(N notifier) {
    _disposables.add(notifier);
    return notifier;
  }

  @override
  void dispose() {
    for (final d in _disposables) {
      d.dispose();
    }
    super.dispose();
  }
}
```

The `late final` initializer runs the first time the field is read, which in practice is the first `build`. This is equivalent to `initState` initialization for resources that are used in `build` - they are created before they are first needed and disposed when the widget leaves the tree.

### What `DisposeBag` deliberately does not cover

**Conditional ownership.** A controller the parent may have supplied - a `TextEditingController?` parameter that the widget creates only when the parent passes `null` - requires tracking whether this widget created it:

```dart
class _SearchFieldState extends State<SearchField> {
  TextEditingController? _ownedController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose(); // only if we created it
    super.dispose();
  }

  TextEditingController get _effectiveController =>
      widget.controller ?? _ownedController!;
}
```

`DisposeBag` cannot express "dispose this only if I created it." That logic stays hand-written. Reaching for `DisposeBag` there and unconditionally disposing a parent-owned controller is a bug - the parent's controller becomes invalid mid-session.

**Subscriptions.** A `StreamSubscription` is not a `ChangeNotifier`. It has a `cancel()` method, not `dispose()`. Cubit stream subscriptions belong in the cubit's `close()`, not in the widget's `dispose()`. A `StreamSubscription` owned by a widget is rare enough that hand-writing its cancellation in `dispose()` is the right call rather than extending `DisposeBag` with a second interface.

**`AnimationController`.** An `AnimationController` requires a `TickerProvider` (usually `SingleTickerProviderStateMixin`). Creating it via `DisposeBag` would hide the `vsync: this` parameter from the call site. It is more readable to declare the animation controller explicitly and call `addDisposable(animationController)` to register it for disposal:

```dart
class _AnimatedCardState extends State<AnimatedCard>
    with DisposeBag, SingleTickerProviderStateMixin {
  late final _animation = addDisposable(
    AnimationController(vsync: this, duration: const Duration(milliseconds: 200)),
  );
}
```

### Using `DisposeBag` in `khulla_ui`

Widgets in `packages/khulla_ui` that own controllers use `DisposeBag` via the package's own import. `DisposeBag` lives in the app package (`lib/core/lifecycle/`), so if a `khulla_ui` primitive needs it the mixin would have to move to the design-system package or be duplicated. In practice, primitives in `khulla_ui` that need a controller accept one as a parameter (the conditional-ownership pattern) rather than creating their own - the app code controls the lifetime. A `khulla_ui` widget that creates and owns a controller internally is the exception; if it arises, moving `DisposeBag` to `khulla_ui` and having the app import it from there is the right migration.

## Consequences

**What this buys**

- A form state with ten fields has ten `late final` declarations and nothing else. No `initState`, no `dispose`, no list to synchronize.
- Adding a field is one line. Removing a field is one line. Neither requires touching any other method.
- The disposal path is in the mixin, not duplicated across every form. A future Flutter API change that requires a different teardown sequence is a one-file fix.
- The debug-mode leak warning for an undisposed controller is structurally impossible for resources created through `DisposeBag`.

**What this costs**

- `late final` initializers run on first read, not on widget construction. A resource that must exist before the first `build` - e.g., a controller whose initial value is computed in the constructor - must still use `initState`. In practice this is rare: `textController(text: widget.initialValue)` covers the common case.
- The mixin is not part of Flutter or a widely known third-party package. A new contributor will encounter `with DisposeBag` and need to look it up. The implementation is short enough (≈30 lines) that reading it resolves the confusion immediately.
- `DisposeBag` disposes every registered resource unconditionally. Registering a resource you do not own is a bug. The rule is: only call `textController()`, `focusNode()`, or `addDisposable()` for resources this widget created. Passing in an externally-owned resource goes in the hand-written disposal path.

## Revisiting

The trigger is a Flutter API change that makes `ChangeNotifier.dispose()` insufficient for some resource type - e.g., a future `SelectionController` with a different teardown contract. Add a typed factory method to `DisposeBag` and update the one file. No call site changes required.

The trigger to retire `DisposeBag` is Flutter shipping a built-in equivalent - a `@mustDispose` annotation or an `AutoDispose` mixin in the framework. At that point the migration is mechanical: replace `with DisposeBag` with the framework equivalent and delete the local mixin.

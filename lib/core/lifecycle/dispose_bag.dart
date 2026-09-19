// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';

/// Collects disposables a [State] creates and releases them automatically.
///
/// Covers the common case - a controller or focus node this widget owns
/// outright - so `initState`/`dispose` boilerplate does not have to be
/// hand-written at every call site. It is composition, not a base class, so it
/// stacks with [WidgetsBindingObserver], [SingleTickerProviderStateMixin], and
/// the rest.
///
/// It deliberately does **not** try to cover conditional ownership - a
/// controller that may be supplied by the parent, and must only be disposed
/// when this widget created it, is a different shape and stays hand-written
/// rather than being forced through a generic API.
///
/// ```dart
/// class _TitleFormState extends State<TitleForm> with DisposeBag {
///   late final _titleController = textController();
///   late final _isbnFocus = focusNode();
///
///   // no initState, no dispose
/// }
/// ```
mixin DisposeBag<T extends StatefulWidget> on State<T> {
  final List<void Function()> _disposables = [];

  /// Registers [value] for automatic disposal via [dispose] and returns it,
  /// so it can be assigned directly to a field.
  C bag<C>(C value, void Function(C value) dispose) {
    _disposables.add(() => dispose(value));
    return value;
  }

  /// Creates a [TextEditingController] this widget owns.
  TextEditingController textController([String? text]) =>
      bag(TextEditingController(text: text), (c) => c.dispose());

  /// Creates a [FocusNode] this widget owns.
  ///
  /// [onChange] is added as a focus-change listener and removed before
  /// disposal - pass it instead of calling `addListener` separately so the
  /// two stay paired.
  FocusNode focusNode({VoidCallback? onChange}) {
    final node = FocusNode();
    if (onChange != null) {
      node.addListener(onChange);
    }
    return bag(node, (n) {
      if (onChange != null) {
        n.removeListener(onChange);
      }
      n.dispose();
    });
  }

  @override
  void dispose() {
    // Reverse order: a later resource may depend on an earlier one (a focus
    // listener capturing a controller), so tear down newest-first.
    for (final release in _disposables.reversed) {
      release();
    }
    _disposables.clear();
    super.dispose();
  }
}

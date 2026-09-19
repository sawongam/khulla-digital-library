// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

/// Delays an action until [duration] has passed without another [run] call.
///
/// Cancel pending work with [cancel] or [dispose].
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  final Duration duration;
  Timer? _timer;

  /// Schedules [action], cancelling any previously scheduled run.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels a pending run without disposing the debouncer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels any pending run.
  void dispose() => cancel();
}

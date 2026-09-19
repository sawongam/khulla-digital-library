// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:khulla/features/circulation/reservation/presentation/reservation_list_refresh.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';

const String _source = 'ReservationExpiryScheduler';

/// Keeps stale holds expiring while the app runs, not only at launch.
///
/// `CirculationRepository.expireStaleHolds` closes a `ready` hold once its
/// pickup window has passed and promotes the next waiting one — correct
/// logic, but calling it once at boot means a hold only expires the next
/// time the app is started. A library open for a full shift needs that to
/// happen during the shift.
@lazySingleton
class ReservationExpiryScheduler {
  ReservationExpiryScheduler(this._circulation, this._refresh);

  final CirculationRepository _circulation;
  final ReservationListRefresh _refresh;

  static const Duration _interval = Duration(minutes: 15);

  Timer? _timer;

  /// Expires stale holds now, then every [_interval] for as long as the app
  /// runs. `bootstrap` calls this once, in place of the one-shot call it used
  /// to make directly — the immediate check keeps today's "expire on launch"
  /// behaviour, including surfacing a failure to the startup screen; failures
  /// on the recurring timer only log, since a background tick has no screen
  /// to report to and must not take a running app down.
  Future<void> start() async {
    await _circulation.expireStaleHolds();
    _refresh.notifyChanged();

    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    try {
      await _circulation.expireStaleHolds();
      _refresh.notifyChanged();
    } on AppException catch (error) {
      AppLogger.warn(
        'Could not expire stale holds on schedule.',
        source: _source,
        error: error,
      );
    }
  }

  @disposeMethod
  void dispose() => _timer?.cancel();
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Lets the reservations list reload when a hold is placed from shell chrome.
@lazySingleton
class ReservationListRefresh {
  VoidCallback? reload;

  void notifyChanged() => reload?.call();
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Lets the titles list reload when a title is added from shell chrome.
@lazySingleton
class TitleListRefresh {
  VoidCallback? reload;

  void notifyChanged() => reload?.call();
}

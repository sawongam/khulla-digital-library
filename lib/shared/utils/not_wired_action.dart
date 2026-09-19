// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Answers a gesture that has no data layer behind it yet.
///
/// Every screen in the app is currently interface-only: the layouts, states
/// and copy are settled, but nothing writes to SQLite. A button that silently
/// does nothing reads as a bug, so each one lands here instead - a toast over
/// the content, which is where a failed write would answer anyway once the
/// repositories exist.
void showNotWiredToast(BuildContext context) =>
    AppToast.info(context, message: context.l10n.commonNotWiredYet);

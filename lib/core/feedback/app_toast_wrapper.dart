// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:toastification/toastification.dart';

/// Wraps the app so [AppToast] can overlay toasts on the widget tree.
class AppToastWrapper extends StatelessWidget {
  const AppToastWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: const ToastificationConfig(
        itemWidth: 500,
        alignment: Alignment.bottomCenter,
      ),
      child: child,
    );
  }
}

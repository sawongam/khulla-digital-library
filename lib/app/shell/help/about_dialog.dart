// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/app/shell/help/widgets/help_about_panel.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What this product is, who made it, and where the source lives.
///
/// Reachable from the account menu on any screen. It is a dialog rather than
/// a route because it is looked up *over* the work in progress — an operator
/// reporting a bug should not lose the screen to find the version number.
class HelpAboutDialog extends StatelessWidget {
  const HelpAboutDialog({super.key});

  /// Presents the about dialog.
  ///
  /// No heading: the panel opens on the product's own name, so a second
  /// *About* above it only repeats what the menu entry just said.
  static Future<void> show(BuildContext context) => AppDialog.show<void>(
    context: context,
    width: AppDialogWidth.xxl,
    content: const HelpAboutDialog(),
    // No footer button: about is read and dismissed, never confirmed, and a
    // lone *Close* only adds a second thing that does what the close chip
    // already does.
    actionsBuilder: (_) => const SizedBox.shrink(),
  );

  @override
  Widget build(BuildContext context) => const HelpAboutPanel();
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/config/app_version.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The app version, shared by the rail footer and More sheet.
///
/// Both spots are shell chrome, so the label lives here once: `v` plus
/// [AppVersion.version] — which reads `version:` in `pubspec.yaml` back from
/// the platform at runtime, so there is no generated copy to regenerate after
/// a bump. The product name is deliberately not shown here; the
/// brand mark above the rail already carries it. The version part is
/// deliberately not localized: it reads the same in every language, same as
/// the About panel.
///
/// [textAlign] defaults to centre for the phone sheet; the rail passes
/// [TextAlign.start] so the line reads with the account row beside it.
class ShellVersionLabel extends StatelessWidget {
  const ShellVersionLabel({
    this.textAlign = TextAlign.center,
    super.key,
  });

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FutureBuilder<String>(
      future: AppVersion.version(),
      builder: (context, snapshot) {
        final version = snapshot.data;
        return Text(
          version == null ? 'v…' : 'v$version',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: context.appTextStyles.caption.copyWith(
            color: colors.mutedForeground,
          ),
        );
      },
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/features/updates/data/update_platform.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';

/// How this install is updated, resolved once before the first frame.
///
/// On Android the answer (Play, or the release-page APK) is an async
/// platform call, and the account menu needs it on its first build. It is
/// resolved on its own, rather than by pre-resolving the repository, so
/// startup does not construct the database before `bootstrap` opens it.
@singleton
class InstalledUpdateChannel {
  InstalledUpdateChannel(this.channel);

  @factoryMethod
  @preResolve
  static Future<InstalledUpdateChannel> detect() async =>
      InstalledUpdateChannel(await detectUpdateChannel());

  final UpdateChannel channel;
}

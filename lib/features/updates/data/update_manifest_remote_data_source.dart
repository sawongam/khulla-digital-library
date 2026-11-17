// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_release.dart';

/// Where the latest published version is read from.
abstract interface class UpdateManifestRemoteDataSource {
  /// The latest release, with the download [channel] would run, if any.
  ///
  /// Throws a `NetworkException` with `updateCheckFailed` when the answer
  /// cannot be fetched or read.
  Future<UpdateRelease> fetchLatestRelease(UpdateChannel channel);
}

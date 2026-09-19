// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:package_info_plus/package_info_plus.dart';

/// The app version at runtime, read back from the platform — never generated.
///
/// `version:` in `pubspec.yaml` is the single source of truth: the Flutter
/// tool bakes it into every build (Android `versionName`/`versionCode`, the
/// Windows file version, and so on), and `package_info_plus` reads that
/// baked-in value back. There is no generated copy to go stale and nothing
/// to regenerate after a bump.
///
/// The platform lookup happens once per process and is shared by every
/// caller. A widget test has no platform channel, so a lookup that fails
/// falls back to `'x.x.x'` rather than crashing the test.
abstract final class AppVersion {
  static Future<PackageInfo>? _packageInfo;

  static Future<PackageInfo> _info() {
    return _packageInfo ??= PackageInfo.fromPlatform();
  }

  /// The released version, `1.2.3`. What a release is tagged and named after.
  static Future<String> version() async {
    try {
      return (await _info()).version;
    } on Object {
      return 'x.x.x';
    }
  }

  /// Version and build together, `1.2.3+4`. Use this where a bug report has
  /// to name an exact build; [version] is what a person reads.
  static Future<String> fullVersion() async {
    try {
      final info = await _info();
      return '${info.version}+${info.buildNumber}';
    } on Object {
      return 'x.x.x';
    }
  }
}

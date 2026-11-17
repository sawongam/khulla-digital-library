// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/config/app_version.dart';

/// Facts about the product itself - where it lives and how to reach it.
///
/// None of it is localized: a URL reads the same in every
/// language, and translating any of them would break the thing it points at.
///
/// The version lives next door in [AppVersion]: `version:` in `pubspec.yaml`,
/// read back from the platform at runtime, so what the about panel shows
/// identifies the download it is running.
abstract final class AppInfo {
  /// Where the source lives.
  static const String repositoryUrl =
      'https://github.com/sawongam/khulla-digital-library';

  /// Where a bug or a request goes.
  static const String issuesUrl = '$repositoryUrl/issues';

  /// The product's own website.
  static const String websiteUrl = 'https://khulladigitallibrary.com';

  /// Where a library asks for a hand: setting up, moving records over, or a
  /// feature it needs. The same address as the website's.
  static const String email = 'info@khulladigitallibrary.com';

  /// Where funding and sponsorship enquiries go.
  static const String fundingEmail = 'funding@khulladigitallibrary.com';

  /// The same inbox, on WhatsApp.
  static const String whatsappUrl = 'https://wa.me/9779819102869';

  /// The newest published release's manifest, written by `release.yaml`.
  ///
  /// `releases/latest/download/` is a plain redirect to the newest
  /// non-prerelease's file - unlike the REST API it has no per-address rate
  /// limit, which a library sharing one connection across desks would hit.
  static const String latestReleaseManifestUrl =
      '$repositoryUrl/releases/latest/download/latest.json';

  /// The page of one release, by its tag.
  static String releaseUrl(String version) =>
      '$repositoryUrl/releases/tag/v$version';

  /// Khulla's Google Play listing - where Android updates come from.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.khulladigitallibrary.app';

  /// The licence the source is released under.
  static const String license = 'AGPL-3.0-only';
}

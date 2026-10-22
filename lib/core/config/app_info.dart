// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/config/app_version.dart';

/// Facts about the product itself - who made it, where it lives.
///
/// None of it is localized: a person's name and a URL read the same in every
/// language, and translating any of them would break the thing it points at.
///
/// The version lives next door in [AppVersion]: `version:` in `pubspec.yaml`,
/// read back from the platform at runtime, so what the about panel shows
/// identifies the download it is running.
abstract final class AppInfo {
  /// The person behind the project, shown in the about panel.
  static const String authorName = 'Sangam Adhikari';

  /// The author's initials, for the avatar beside the name.
  static String get authorInitials => authorName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  /// The author's site.
  static const String authorSite = 'https://sangamadhikari.com';

  /// Where the source lives.
  static const String repositoryUrl =
      'https://github.com/sawongam/khulla-digital-library';

  /// Where a bug or a request goes.
  static const String issuesUrl = '$repositoryUrl/issues';

  /// The product's own website.
  static const String websiteUrl = 'https://khulladigitallibrary.com';

  /// Where a library asks for a hand: setting up, moving records over, or a
  /// feature it needs. The same number and address as the website's.
  static const String whatsappUrl = 'https://wa.me/9779819102869';

  /// The WhatsApp number as people read it.
  static const String whatsappDisplay = '+977 981-9102869';

  /// The address for the same, by email.
  static const String email = 'info@sangamadhikari.com';

  /// The licence the source is released under.
  static const String license = 'AGPL-3.0-only';
}

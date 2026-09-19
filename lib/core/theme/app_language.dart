// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';

/// The device-level interface language, stored alongside the theme.
///
/// English is the default until the operator picks Nepali on the appearance
/// page. Nothing about it reaches the catalogue file.
enum AppLanguage { english, nepali }

extension AppLanguageX on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.nepali => const Locale('ne'),
  };
}

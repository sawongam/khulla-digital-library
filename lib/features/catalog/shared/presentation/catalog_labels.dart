// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Localized names and icons for reference formats and copy standing.
extension TitleFormatCodeX on String? {
  AppIconSpec get formatIcon => switch (this) {
    'book' => AppIcons.book,
    'journal' => AppIcons.article,
    'magazine' => AppIcons.openBook,
    'audiobook' => AppIcons.audio,
    'video' => AppIcons.video,
    'ebook' => AppIcons.devices,
    'other' => AppIcons.inventory,
    _ => AppIcons.article,
  };

  String formatLabel(AppLocalizations l10n) => switch (this) {
    'book' => l10n.formatBook,
    'journal' => l10n.formatJournal,
    'magazine' => l10n.formatMagazine,
    'audiobook' => l10n.formatAudio,
    'video' => l10n.formatVideo,
    'ebook' => l10n.formatDigital,
    'other' => l10n.formatOther,
    _ => l10n.formatOther,
  };
}

extension TitleFormatX on TitleFormat {
  AppIconSpec get icon => switch (code) {
    null => AppIcons.article,
    final value => value.formatIcon,
  };

  String label(AppLocalizations l10n) =>
      code == null ? name : code!.formatLabel(l10n);
}

extension CopyStatusX on CopyStatus {
  String label(AppLocalizations l10n) => switch (this) {
    CopyStatus.available => l10n.statusAvailable,
    CopyStatus.onLoan => l10n.statusOnLoan,
    CopyStatus.reserved => l10n.statusReserved,
    CopyStatus.lost => l10n.statusLost,
    CopyStatus.damaged => l10n.statusDamaged,
  };

  AppStatusTone get tone => switch (this) {
    CopyStatus.available => AppStatusTone.success,
    CopyStatus.onLoan => AppStatusTone.brand,
    CopyStatus.reserved => AppStatusTone.info,
    CopyStatus.lost => AppStatusTone.danger,
    CopyStatus.damaged => AppStatusTone.warning,
  };
}

extension CopyConditionX on CopyCondition {
  String label(AppLocalizations l10n) => switch (this) {
    CopyCondition.asNew => l10n.conditionNew,
    CopyCondition.good => l10n.conditionGood,
    CopyCondition.fair => l10n.conditionFair,
    CopyCondition.poor => l10n.conditionPoor,
  };
}

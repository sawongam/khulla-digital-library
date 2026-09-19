// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/l10n/l10n.dart';

/// Localized, user-facing copy for a data-layer failure.
///
/// `AppException.message` is a developer-facing fallback; presentation should
/// always render this instead so error copy lives in the ARB files like every
/// other string.
extension AppExceptionL10n on AppException {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    DuplicateRecordException() => l10n.errorDuplicateRecord,
    NotFoundException() => l10n.errorNotFound,
    InvalidInputException() => l10n.errorInvalidInput,
    ConflictException() => l10n.errorConflict,
    DatabaseUnavailableException() => l10n.errorDatabaseUnavailable,
    DatabaseFailureException() => l10n.errorDatabaseFailure,
    StorageException() => l10n.errorStorage,
    UnknownException() => l10n.errorUnknown,
  };
}

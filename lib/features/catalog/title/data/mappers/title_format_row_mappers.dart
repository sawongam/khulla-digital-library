// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';

/// Maps [TitleFormatRow] to [TitleFormat] and back for drift writes.
extension TitleFormatRowX on TitleFormatRow {
  TitleFormat toDomain() => TitleFormat(
    id: id,
    code: code,
    name: name,
    sortOrder: sortOrder,
    isSystem: isSystem,
    archivedAt: archivedAt,
    createdAt: createdAt,
  );
}

extension TitleFormatDomainX on TitleFormat {
  TitleFormatsCompanion toCompanion() => TitleFormatsCompanion(
    id: Value(id),
    code: Value(code),
    name: Value(name),
    sortOrder: Value(sortOrder),
    isSystem: Value(isSystem),
    archivedAt: Value(archivedAt),
    createdAt: Value(createdAt),
  );
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';

/// Maps [FineRow] to [Fine] and back for drift writes.
extension FineRowMapper on FineRow {
  Fine toDomain({
    String? memberName,
    String? titleName,
  }) => Fine(
    id: id,
    memberId: memberId,
    loanId: loanId,
    reason: reason,
    assessed: assessed,
    paid: paid,
    waived: waived,
    raisedAt: raisedAt,
    settledAt: settledAt,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
    memberName: memberName,
    titleName: titleName,
  );
}

extension FineDomainMapper on Fine {
  FinesCompanion toCompanion() => FinesCompanion(
    id: Value(id),
    memberId: Value(memberId),
    loanId: Value(loanId),
    reason: Value(reason),
    assessed: Value(assessed),
    paid: Value(paid),
    waived: Value(waived),
    raisedAt: Value(raisedAt),
    settledAt: Value(settledAt),
    note: Value(note),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

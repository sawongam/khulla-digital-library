// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// What may stop a member being deleted, as a pure function of the facts.
///
/// The data source gathers the counts inside its transaction and asks here;
/// a member's past, returned loans and settled fines never block a delete -
/// they stay, without a name.
library;

import 'package:khulla/core/error/app_exception.dart';

/// Refuses deleting a member who still has a book out or owes money.
///
/// [openLoanCount] is loans not yet returned; [unpaidFineCount] is fines
/// where paid plus waived is still less than assessed.
void ensureMemberDeletable({
  required int openLoanCount,
  required int unpaidFineCount,
}) {
  if (openLoanCount > 0) {
    throw const ConflictException.because(AppErrorReason.memberHasOpenLoans);
  }
  if (unpaidFineCount > 0) {
    throw const ConflictException.because(AppErrorReason.memberHasUnpaidFines);
  }
}

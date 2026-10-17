// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// The circulation desk's rules, as pure functions of the facts they judge.
///
/// The repository gathers those facts inside its transaction - the member's
/// standing, the copy's status, how many loans are open - and asks these
/// functions whether the action may go ahead. Each one throws an
/// [AppException] carrying the [AppErrorReason] that refused it, so the
/// desk is told which rule fired rather than that one did.
///
/// Nothing here touches the database, so every rule is checkable in a plain
/// unit test, and a screen previewing an action (the due date the check-out
/// desk shows) computes it with the same function the write does.
library;

import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/time/calendar_days.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';

/// The date a loan made on [checkedOutOn] falls due.
DateTime dueDateFor(DateTime checkedOutOn, EffectiveLoanRules rules) =>
    addCalendarDays(checkedOutOn, rules.loanPeriodDays);

/// The new due date when a loan due on [currentDueAt] is renewed.
DateTime renewedDueDate(DateTime currentDueAt, EffectiveLoanRules rules) =>
    addCalendarDays(
      currentDueAt,
      rules.renewalPeriodDays ?? rules.loanPeriodDays,
    );

/// Refuses a member who may not borrow or place holds on [today]: archived,
/// suspended, or past their membership's expiry date.
void ensureMemberInGoodStanding({
  required DateTime? archivedAt,
  required DateTime? suspendedAt,
  required DateTime? expiresAt,
  required DateTime today,
}) {
  ensureMemberNotArchived(archivedAt);
  if (suspendedAt != null) {
    throw const ConflictException.because(AppErrorReason.memberSuspended);
  }
  if (expiresAt != null && daysBetween(today, expiresAt) < 0) {
    throw const ConflictException.because(AppErrorReason.membershipExpired);
  }
}

/// Refuses any new charge or loan against an archived member.
void ensureMemberNotArchived(DateTime? archivedAt) {
  if (archivedAt != null) {
    throw const ConflictException.because(AppErrorReason.memberArchived);
  }
}

/// Refuses a copy whose record says it cannot circulate at all.
void ensureCopyCanCirculate({
  required DateTime? copyArchivedAt,
  required DateTime? titleArchivedAt,
  required bool titleLendable,
}) {
  if (copyArchivedAt != null) {
    throw const ConflictException.because(AppErrorReason.copyArchived);
  }
  if (!titleLendable) {
    throw const ConflictException.because(AppErrorReason.titleNotLendable);
  }
  if (titleArchivedAt != null) {
    throw const ConflictException.because(AppErrorReason.titleArchived);
  }
}

/// Refuses a copy that is not on the shelf for [memberId]: out on loan,
/// missing, or set aside for somebody else's hold.
///
/// [readyHoldMemberId] is whose ready hold the copy is set aside for, when
/// it is reserved.
void ensureCopyAvailableTo({
  required CopyStatus status,
  required String memberId,
  required String? readyHoldMemberId,
}) {
  if (status == CopyStatus.reserved) {
    if (readyHoldMemberId != memberId) {
      throw const ConflictException.because(
        AppErrorReason.copyReservedForAnotherMember,
      );
    }
    return;
  }
  if (status != CopyStatus.available) {
    throw const ConflictException.because(AppErrorReason.copyNotAvailable);
  }
}

/// Refuses a loan that would take the member past their borrowing limit.
void ensureUnderBorrowingLimit({
  required int openLoans,
  required EffectiveLoanRules rules,
}) {
  if (openLoans >= rules.borrowingLimit) {
    throw const ConflictException.because(
      AppErrorReason.borrowingLimitReached,
    );
  }
}

/// Refuses a borrower with overdue loans, when the rules block them.
void ensureNoBlockingOverdues({
  required bool hasOverdueLoans,
  required EffectiveLoanRules rules,
}) {
  if (rules.blockOverdueBorrowers && hasOverdueLoans) {
    throw const ConflictException.because(
      AppErrorReason.memberHasOverdueLoans,
    );
  }
}

/// Refuses a borrower who owes more than the rules allow; no ceiling set
/// means no refusal.
void ensureFinesWithinLimit({
  required Money outstanding,
  required EffectiveLoanRules rules,
}) {
  final ceiling = rules.maxOutstandingFine;
  if (ceiling != null && outstanding > ceiling) {
    throw const ConflictException.because(
      AppErrorReason.outstandingFinesTooHigh,
    );
  }
}

/// Refuses to lend a title past the front of its hold queue.
///
/// [firstWaitingMemberId] is the member whose waiting hold is oldest, or null
/// when nobody is waiting.
void ensureFirstInHoldQueue({
  required String memberId,
  required String? firstWaitingMemberId,
}) {
  if (firstWaitingMemberId != null && firstWaitingMemberId != memberId) {
    throw const ConflictException.because(AppErrorReason.earlierHoldOnTitle);
  }
}

/// Refuses a renewal of a closed loan, one at its renewal limit, or one
/// whose title somebody else is waiting for.
void ensureRenewable({
  required DateTime? returnedAt,
  required int renewalCount,
  required int waitingHolds,
  required EffectiveLoanRules rules,
}) {
  if (returnedAt != null) {
    throw const ConflictException.because(AppErrorReason.loanAlreadyReturned);
  }
  if (renewalCount >= rules.renewalLimit) {
    throw const ConflictException.because(AppErrorReason.renewalLimitReached);
  }
  if (waitingHolds > 0) {
    throw const ConflictException.because(AppErrorReason.holdBlocksRenewal);
  }
}

/// Refuses a hold on a title that cannot circulate, or one past the
/// member's hold limit.
void ensureHoldAllowed({
  required DateTime? titleArchivedAt,
  required bool titleLendable,
  required int activeHolds,
  required EffectiveLoanRules rules,
}) {
  if (titleArchivedAt != null) {
    throw const ConflictException.because(AppErrorReason.titleArchived);
  }
  if (!titleLendable) {
    throw const ConflictException.because(AppErrorReason.titleNotLendable);
  }
  if (activeHolds >= rules.reservationLimit) {
    throw const ConflictException.because(AppErrorReason.holdLimitReached);
  }
}

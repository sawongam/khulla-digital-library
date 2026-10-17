// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_rules.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';

/// The desk's rules as pure functions - no database, just the facts.
void main() {
  final rules = EffectiveLoanRules(
    loanPeriodDays: 14,
    borrowingLimit: 3,
    renewalLimit: 2,
    finePerDay: Money.major(5),
    graceDays: 0,
    maximumFinePerCopy: Money.major(500),
    membershipDurationMonths: 12,
    reservationLimit: 2,
    holdShelfDays: 7,
    blockOverdueBorrowers: true,
    autoRenewWhenUnreserved: false,
    renewalPeriodDays: 7,
    maxOutstandingFine: Money.major(100),
  );

  Matcher refusedBecause(AppErrorReason reason) => throwsA(
    isA<ConflictException>().having((e) => e.reason, 'reason', reason),
  );

  group('due dates', () {
    test('a loan falls due one loan period after it is made', () {
      expect(
        dueDateFor(DateTime(2026, 10, 25, 15, 30), rules),
        DateTime(2026, 11, 8),
      );
    });

    test(
      'a renewal extends from the current due date by the renewal period',
      () {
        expect(
          renewedDueDate(DateTime(2026, 11, 8), rules),
          DateTime(2026, 11, 15),
        );
        expect(
          renewedDueDate(
            DateTime(2026, 11, 8),
            rules.copyWith(renewalPeriodDays: null),
          ),
          DateTime(2026, 11, 22),
        );
      },
    );
  });

  group('ensureMemberInGoodStanding', () {
    final today = DateTime(2026, 6, 15);

    test('lets a current member through', () {
      expect(
        () => ensureMemberInGoodStanding(
          archivedAt: null,
          suspendedAt: null,
          expiresAt: DateTime(2026, 6, 15),
          today: today,
        ),
        returnsNormally,
      );
    });

    test('refuses archived, then suspended, then expired', () {
      expect(
        () => ensureMemberInGoodStanding(
          archivedAt: today,
          suspendedAt: today,
          expiresAt: DateTime(2026, 6, 14),
          today: today,
        ),
        refusedBecause(AppErrorReason.memberArchived),
      );
      expect(
        () => ensureMemberInGoodStanding(
          archivedAt: null,
          suspendedAt: today,
          expiresAt: null,
          today: today,
        ),
        refusedBecause(AppErrorReason.memberSuspended),
      );
      expect(
        () => ensureMemberInGoodStanding(
          archivedAt: null,
          suspendedAt: null,
          expiresAt: DateTime(2026, 6, 14, 23, 59),
          today: today,
        ),
        refusedBecause(AppErrorReason.membershipExpired),
      );
    });
  });

  group('check-out rules', () {
    test('a copy is refused for each reason its record gives', () {
      expect(
        () => ensureCopyCanCirculate(
          copyArchivedAt: DateTime(2026),
          titleArchivedAt: null,
          titleLendable: true,
        ),
        refusedBecause(AppErrorReason.copyArchived),
      );
      expect(
        () => ensureCopyCanCirculate(
          copyArchivedAt: null,
          titleArchivedAt: null,
          titleLendable: false,
        ),
        refusedBecause(AppErrorReason.titleNotLendable),
      );
      expect(
        () => ensureCopyCanCirculate(
          copyArchivedAt: null,
          titleArchivedAt: DateTime(2026),
          titleLendable: true,
        ),
        refusedBecause(AppErrorReason.titleArchived),
      );
    });

    test('a reserved copy goes only to the member it is held for', () {
      expect(
        () => ensureCopyAvailableTo(
          status: CopyStatus.reserved,
          memberId: 'm1',
          readyHoldMemberId: 'm1',
        ),
        returnsNormally,
      );
      expect(
        () => ensureCopyAvailableTo(
          status: CopyStatus.reserved,
          memberId: 'm1',
          readyHoldMemberId: 'm2',
        ),
        refusedBecause(AppErrorReason.copyReservedForAnotherMember),
      );
      expect(
        () => ensureCopyAvailableTo(
          status: CopyStatus.onLoan,
          memberId: 'm1',
          readyHoldMemberId: null,
        ),
        refusedBecause(AppErrorReason.copyNotAvailable),
      );
    });

    test('the borrowing limit is a ceiling, not a target', () {
      expect(
        () => ensureUnderBorrowingLimit(openLoans: 2, rules: rules),
        returnsNormally,
      );
      expect(
        () => ensureUnderBorrowingLimit(openLoans: 3, rules: rules),
        refusedBecause(AppErrorReason.borrowingLimitReached),
      );
    });

    test('overdue loans block only when the rules say so', () {
      expect(
        () => ensureNoBlockingOverdues(hasOverdueLoans: true, rules: rules),
        refusedBecause(AppErrorReason.memberHasOverdueLoans),
      );
      expect(
        () => ensureNoBlockingOverdues(
          hasOverdueLoans: true,
          rules: rules.copyWith(blockOverdueBorrowers: false),
        ),
        returnsNormally,
      );
    });

    test('outstanding fines block only above a ceiling that is set', () {
      expect(
        () => ensureFinesWithinLimit(
          outstanding: Money.major(100),
          rules: rules,
        ),
        returnsNormally,
      );
      expect(
        () => ensureFinesWithinLimit(
          outstanding: Money.major(100.01),
          rules: rules,
        ),
        refusedBecause(AppErrorReason.outstandingFinesTooHigh),
      );
      expect(
        () => ensureFinesWithinLimit(
          outstanding: Money.major(10000),
          rules: rules.copyWith(maxOutstandingFine: null),
        ),
        returnsNormally,
      );
    });

    test('the front of the hold queue goes first', () {
      expect(
        () =>
            ensureFirstInHoldQueue(memberId: 'm1', firstWaitingMemberId: null),
        returnsNormally,
      );
      expect(
        () =>
            ensureFirstInHoldQueue(memberId: 'm1', firstWaitingMemberId: 'm1'),
        returnsNormally,
      );
      expect(
        () =>
            ensureFirstInHoldQueue(memberId: 'm1', firstWaitingMemberId: 'm2'),
        refusedBecause(AppErrorReason.earlierHoldOnTitle),
      );
    });
  });

  group('renewal and hold rules', () {
    test('a renewal is refused for a closed, spent or wanted loan', () {
      expect(
        () => ensureRenewable(
          returnedAt: DateTime(2026),
          renewalCount: 0,
          waitingHolds: 0,
          rules: rules,
        ),
        refusedBecause(AppErrorReason.loanAlreadyReturned),
      );
      expect(
        () => ensureRenewable(
          returnedAt: null,
          renewalCount: 2,
          waitingHolds: 0,
          rules: rules,
        ),
        refusedBecause(AppErrorReason.renewalLimitReached),
      );
      expect(
        () => ensureRenewable(
          returnedAt: null,
          renewalCount: 1,
          waitingHolds: 1,
          rules: rules,
        ),
        refusedBecause(AppErrorReason.holdBlocksRenewal),
      );
    });

    test('a hold is refused past the member hold limit', () {
      expect(
        () => ensureHoldAllowed(
          titleArchivedAt: null,
          titleLendable: true,
          activeHolds: 2,
          rules: rules,
        ),
        refusedBecause(AppErrorReason.holdLimitReached),
      );
    });
  });
}

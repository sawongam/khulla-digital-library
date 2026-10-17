// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine_query.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';

/// Checkout, return, renew, holds and the ledgers that hang off them.
///
/// Desk writes run in transactions; list screens read through the typed
/// query objects on each sub-resource.
///
/// Checking a copy out or in is recorded against the account signed in on
/// this device, which the repository reads for itself - a caller cannot
/// name somebody else, or nobody. Both throw `SignedOutException` when the
/// session has ended under an open screen.

/// One copy scanned at the returns desk.
typedef ReturnCopyInput = ({
  String barcode,
  CopyCondition condition,
});

abstract interface class CirculationRepository {
  Future<Loan> checkOutCopy({
    required String memberId,
    required String barcode,
  });

  /// Processes every item in one transaction so a basket either checks out
  /// in full or not at all.
  Future<List<Loan>> checkOutCopies({
    required String memberId,
    required List<String> barcodes,
  });

  Future<Loan> returnCopy({
    required String barcode,
    required CopyCondition condition,
    bool waiveFine = false,
  });

  /// Processes every item in one transaction so the desk stays consistent.
  Future<List<Loan>> returnCopies({
    required List<ReturnCopyInput> copies,
    bool waiveFine = false,
  });

  Future<Loan> renewLoan(String loanId);

  Future<Reservation> placeHold({
    required String memberId,
    required String titleId,
  });

  Future<void> cancelHold(String reservationId);

  /// Assigns the next available copy and moves a waiting hold to ready.
  Future<Reservation> markHoldReady(String reservationId);

  Future<Fine> collectFine(String fineId);

  Future<Fine> waiveFine(String fineId);

  /// Assesses a one-off fine by hand - a lost/damaged copy or a membership
  /// fee. The automatic overdue fine on return does not go through here.
  Future<Fine> chargeFine({
    required String memberId,
    required FineReason reason,
    required Money amount,
    String? note,
  });

  Future<void> expireStaleHolds();

  /// The loan rules that apply to [memberId] - the library's defaults with
  /// their member category's overrides on top. What the check-out desk
  /// previews a due date from, read the same way the check-out itself reads
  /// it.
  Future<EffectiveLoanRules> findEffectiveRulesForMember(String memberId);

  Future<LoanListResult> findOpenLoans(LoanQuery query);

  Future<LoanListResult> findLoans(LoanQuery query);

  Future<Loan?> findOpenLoanByBarcode(String barcode);

  Future<Loan?> findLoan(String id);

  Future<FineListResult> findFines(FineQuery query);

  Future<Fine?> findFine(String id);

  Future<ReservationListResult> findReservations(ReservationQuery query);

  Future<Reservation?> findReservation(String id);
}

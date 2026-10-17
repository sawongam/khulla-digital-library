// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/time/calendar_days.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/fine/data/fine_local_data_source.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine_query.dart';
import 'package:khulla/features/circulation/loan/data/loan_local_data_source.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';
import 'package:khulla/features/circulation/reservation/data/reservation_local_data_source.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';
import 'package:khulla/features/circulation/shared/data/circulation_copies.dart';
import 'package:khulla/features/circulation/shared/data/circulation_fine_writes.dart';
import 'package:khulla/features/circulation/shared/data/circulation_hold_queue.dart';
import 'package:khulla/features/circulation/shared/data/circulation_loan_writes.dart';
import 'package:khulla/features/circulation/shared/data/effective_rules_reader.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_rules.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';
import 'package:khulla/features/staff_auth/domain/session_repository.dart';

/// [CirculationRepository] over the local catalogue.
///
/// Orchestration only: each desk write gathers the facts its rules need and
/// writes the result in one transaction, so copy status, loan rows, fine
/// snapshots and the reservation queue stay consistent. The rules themselves
/// are the pure functions in `circulation_rules.dart`; row writes live in
/// transaction-scoped helpers sharing this database instance
/// ([EffectiveRulesReader], [CirculationLoanWrites], [CirculationFineWrites],
/// [CirculationHoldQueue]); list reads delegate to [LoanLocalDataSource],
/// [FineLocalDataSource] and [ReservationLocalDataSource].
///
/// Check-out and return are attributed to [SessionRepository]'s signed-in
/// account, read here rather than passed in.
@LazySingleton(as: CirculationRepository)
class CirculationRepositoryImpl implements CirculationRepository {
  CirculationRepositoryImpl(
    this._db,
    this._loanDataSource,
    this._fineDataSource,
    this._reservationDataSource,
    this._session,
  );

  final AppDatabase _db;
  final LoanLocalDataSource _loanDataSource;
  final FineLocalDataSource _fineDataSource;
  final ReservationLocalDataSource _reservationDataSource;
  final SessionRepository _session;

  late final _rules = EffectiveRulesReader(_db);
  late final _loanWrites = CirculationLoanWrites(_db);
  late final _fineWrites = CirculationFineWrites(_db);
  late final _holdQueue = CirculationHoldQueue(_db, _rules);

  static const String _source = 'CirculationRepositoryImpl';

  @override
  Future<Loan> checkOutCopy({
    required String memberId,
    required String barcode,
  }) => guardDatabase(
    () {
      final staffId = _session.requireSignedInStaff().id;
      return _db.transaction(
        () => _checkOutCopy(
          memberId: memberId,
          barcode: barcode.trim(),
          staffId: staffId,
        ),
      );
    },
    source: '$_source.checkOutCopy',
  );

  @override
  Future<List<Loan>> checkOutCopies({
    required String memberId,
    required List<String> barcodes,
  }) => guardDatabase(
    () {
      final staffId = _session.requireSignedInStaff().id;
      return _db.transaction(() async {
        final loans = <Loan>[];
        for (final barcode in barcodes) {
          loans.add(
            await _checkOutCopy(
              memberId: memberId,
              barcode: barcode.trim(),
              staffId: staffId,
            ),
          );
        }
        return loans;
      });
    },
    source: '$_source.checkOutCopies',
  );

  Future<Loan> _checkOutCopy({
    required String memberId,
    required String barcode,
    required String staffId,
  }) async {
    final now = DateTime.now();
    final today = dateOnly(now);

    final copyRow = await (_db.select(
      _db.copies,
    )..where((copy) => copy.barcode.equals(barcode))).getSingleOrNull();
    if (copyRow == null) {
      throw const NotFoundException.because(AppErrorReason.copyNotFound);
    }

    final titleRow = await (_db.select(
      _db.titles,
    )..where((title) => title.id.equals(copyRow.titleId))).getSingleOrNull();
    if (titleRow == null) {
      throw const NotFoundException.because(AppErrorReason.titleNotFound);
    }

    final memberRow = await (_db.select(
      _db.members,
    )..where((member) => member.id.equals(memberId))).getSingleOrNull();
    if (memberRow == null) {
      throw const NotFoundException.because(AppErrorReason.memberNotFound);
    }

    final rules = await _rules.loadEffectiveRules(memberRow.memberTypeId);

    // Checked in this order, and each fact read only once the rules before
    // it have passed, so the desk is told the first thing standing in the
    // way - and a cheap refusal never pays for an expensive count.
    ensureMemberInGoodStanding(
      archivedAt: memberRow.archivedAt,
      suspendedAt: memberRow.suspendedAt,
      expiresAt: memberRow.expiresAt,
      today: today,
    );
    ensureCopyCanCirculate(
      copyArchivedAt: copyRow.archivedAt,
      titleArchivedAt: titleRow.archivedAt,
      titleLendable: titleRow.lendable,
    );
    ensureCopyAvailableTo(
      status: copyRow.status,
      memberId: memberId,
      readyHoldMemberId: copyRow.status == CopyStatus.reserved
          ? (await _holdQueue.findReadyHoldForCopy(copyRow.id))?.memberId
          : null,
    );
    ensureUnderBorrowingLimit(
      openLoans: await _loanDataSource.countOpenLoansForMember(memberId),
      rules: rules,
    );
    ensureNoBlockingOverdues(
      hasOverdueLoans:
          rules.blockOverdueBorrowers &&
          await _loanDataSource.memberHasOverdueLoans(memberId),
      rules: rules,
    );
    ensureFinesWithinLimit(
      outstanding: rules.maxOutstandingFine == null
          ? Money.zero
          : await _fineDataSource.outstandingForMember(memberId),
      rules: rules,
    );
    ensureFirstInHoldQueue(
      memberId: memberId,
      firstWaitingMemberId:
          (await _reservationDataSource.findFirstWaitingHoldForTitle(
            copyRow.titleId,
          ))?.memberId,
    );

    final loanId = await _loanWrites.insertCheckoutLoan(
      copyId: copyRow.id,
      memberId: memberId,
      checkedOutAt: now,
      dueAt: dueDateFor(today, rules),
      ruleLoanPeriodDays: rules.loanPeriodDays,
      ruleFinePerDay: rules.finePerDay,
      ruleGraceDays: rules.graceDays,
      ruleMaximumFine: rules.maximumFinePerCopy,
      staffId: staffId,
    );

    await setCopyStatus(_db, copyRow.id, CopyStatus.onLoan);
    await _holdQueue.fulfillMemberHold(
      memberId: memberId,
      titleId: copyRow.titleId,
    );

    return (await _loanDataSource.findLoanById(loanId))!;
  }

  @override
  Future<Loan> returnCopy({
    required String barcode,
    required CopyCondition condition,
    bool waiveFine = false,
  }) => guardDatabase(
    () {
      final staffId = _session.requireSignedInStaff().id;
      return _db.transaction(
        () => _returnCopy(
          barcode: barcode.trim(),
          condition: condition,
          waiveFine: waiveFine,
          staffId: staffId,
        ),
      );
    },
    source: '$_source.returnCopy',
  );

  @override
  Future<List<Loan>> returnCopies({
    required List<ReturnCopyInput> copies,
    bool waiveFine = false,
  }) => guardDatabase(
    () {
      final staffId = _session.requireSignedInStaff().id;
      return _db.transaction(() async {
        final closed = <Loan>[];
        for (final item in copies) {
          closed.add(
            await _returnCopy(
              barcode: item.barcode.trim(),
              condition: item.condition,
              waiveFine: waiveFine,
              staffId: staffId,
            ),
          );
        }
        return closed;
      });
    },
    source: '$_source.returnCopies',
  );

  Future<Loan> _returnCopy({
    required String barcode,
    required CopyCondition condition,
    required bool waiveFine,
    required String staffId,
  }) async {
    final now = DateTime.now();
    final today = dateOnly(now);

    final copyRow = await (_db.select(
      _db.copies,
    )..where((copy) => copy.barcode.equals(barcode))).getSingleOrNull();
    if (copyRow == null) {
      throw const NotFoundException.because(AppErrorReason.copyNotFound);
    }

    final openLoan = await _loanDataSource.findOpenLoanByCopyId(copyRow.id);
    if (openLoan == null) {
      throw const NotFoundException.because(AppErrorReason.copyNotOnLoan);
    }

    await _loanWrites.markLoanReturned(
      loanId: openLoan.id,
      condition: condition,
      staffId: staffId,
    );

    final fineAmount = computeOverdueFine(
      dueAt: openLoan.dueAt,
      asOf: today,
      finePerDay: openLoan.ruleFinePerDay,
      graceDays: openLoan.ruleGraceDays,
      maximumFine: openLoan.ruleMaximumFine,
    );

    if (fineAmount.isPositive && !waiveFine) {
      await _fineWrites.insertOverdueFine(
        memberId: openLoan.memberId,
        loanId: openLoan.id,
        amount: fineAmount,
      );
    }

    await _holdQueue.promoteOrRelease(
      copyId: copyRow.id,
      titleId: copyRow.titleId,
    );

    return (await _loanDataSource.findLoanById(openLoan.id))!;
  }

  @override
  Future<Loan> renewLoan(String loanId) => guardDatabase(
    () => _db.transaction(() => _renewLoan(loanId: loanId)),
    source: '$_source.renewLoan',
  );

  Future<Loan> _renewLoan({required String loanId}) async {
    final loan = await _loanDataSource.findLoanById(loanId);
    if (loan == null) {
      throw const NotFoundException.because(AppErrorReason.loanNotFound);
    }
    if (loan.returnedAt != null) {
      throw const ConflictException.because(AppErrorReason.loanAlreadyReturned);
    }

    final copyRow = await (_db.select(
      _db.copies,
    )..where((copy) => copy.id.equals(loan.copyId))).getSingleOrNull();
    if (copyRow == null) {
      throw const NotFoundException.because(AppErrorReason.copyNotFound);
    }

    final rules = await _rules.loadEffectiveRulesForMember(loan.memberId);

    ensureRenewable(
      returnedAt: loan.returnedAt,
      renewalCount: loan.renewalCount,
      waitingHolds: await _holdQueue.countWaitingHolds(copyRow.titleId),
      rules: rules,
    );

    await _loanWrites.extendLoanDue(
      loanId: loanId,
      newDueAt: renewedDueDate(loan.dueAt, rules),
    );

    return (await _loanDataSource.findLoanById(loanId))!;
  }

  @override
  Future<Reservation> placeHold({
    required String memberId,
    required String titleId,
  }) => guardDatabase(
    () => _db.transaction(
      () => _placeHold(memberId: memberId, titleId: titleId),
    ),
    source: '$_source.placeHold',
  );

  Future<Reservation> _placeHold({
    required String memberId,
    required String titleId,
  }) async {
    final now = DateTime.now();
    final today = dateOnly(now);

    final memberRow = await (_db.select(
      _db.members,
    )..where((member) => member.id.equals(memberId))).getSingleOrNull();
    if (memberRow == null) {
      throw const NotFoundException.because(AppErrorReason.memberNotFound);
    }

    final titleRow = await (_db.select(
      _db.titles,
    )..where((title) => title.id.equals(titleId))).getSingleOrNull();
    if (titleRow == null) {
      throw const NotFoundException.because(AppErrorReason.titleNotFound);
    }

    final rules = await _rules.loadEffectiveRules(memberRow.memberTypeId);

    ensureMemberInGoodStanding(
      archivedAt: memberRow.archivedAt,
      suspendedAt: memberRow.suspendedAt,
      expiresAt: memberRow.expiresAt,
      today: today,
    );
    ensureHoldAllowed(
      titleArchivedAt: titleRow.archivedAt,
      titleLendable: titleRow.lendable,
      activeHolds: await _reservationDataSource.countActiveHoldsForMember(
        memberId,
      ),
      rules: rules,
    );

    final reservationId = await _holdQueue.insertWaitingHold(
      memberId: memberId,
      titleId: titleId,
    );
    return (await _reservationDataSource.findReservationById(
      reservationId,
    ))!;
  }

  @override
  Future<void> cancelHold(String reservationId) => guardDatabase(
    () => _db.transaction(() => _holdQueue.cancelOpenHold(reservationId)),
    source: '$_source.cancelHold',
  );

  @override
  Future<Reservation> markHoldReady(String reservationId) => guardDatabase(
    () => _db.transaction(() async {
      final id = await _holdQueue.markHoldReady(reservationId);
      return (await _reservationDataSource.findReservationById(id))!;
    }),
    source: '$_source.markHoldReady',
  );

  @override
  Future<Fine> collectFine(String fineId) => guardDatabase(
    () => _db.transaction(() async {
      await _fineWrites.settleFine(id: fineId, waive: false);
      return (await findFine(fineId))!;
    }),
    source: '$_source.collectFine',
  );

  @override
  Future<Fine> waiveFine(String fineId) => guardDatabase(
    () => _db.transaction(() async {
      await _fineWrites.settleFine(id: fineId, waive: true);
      return (await findFine(fineId))!;
    }),
    source: '$_source.waiveFine',
  );

  @override
  Future<Fine> chargeFine({
    required String memberId,
    required FineReason reason,
    required Money amount,
    String? note,
  }) => guardDatabase(
    () => _db.transaction(() async {
      final id = await _fineWrites.chargeManualFine(
        memberId: memberId,
        reason: reason,
        amount: amount,
        note: note,
      );
      return (await findFine(id))!;
    }),
    source: '$_source.chargeFine',
  );

  @override
  Future<void> expireStaleHolds() => guardDatabase(
    () => _db.transaction(_holdQueue.expireStaleReady),
    source: '$_source.expireStaleHolds',
  );

  @override
  Future<EffectiveLoanRules> findEffectiveRulesForMember(String memberId) =>
      _rules.loadEffectiveRulesForMember(memberId);

  @override
  Future<LoanListResult> findOpenLoans(LoanQuery query) =>
      _loanDataSource.findOpenLoans(query);

  @override
  Future<LoanListResult> findLoans(LoanQuery query) =>
      _loanDataSource.findLoans(query);

  @override
  Future<Loan?> findOpenLoanByBarcode(String barcode) =>
      _loanDataSource.findOpenLoanByBarcode(barcode.trim());

  @override
  Future<Loan?> findLoan(String id) => _loanDataSource.findLoanById(id);

  @override
  Future<FineListResult> findFines(FineQuery query) =>
      _fineDataSource.findFines(query);

  @override
  Future<Fine?> findFine(String id) => _fineDataSource.findFineById(id);

  @override
  Future<ReservationListResult> findReservations(ReservationQuery query) =>
      _reservationDataSource.findReservations(query);

  @override
  Future<Reservation?> findReservation(String id) =>
      _reservationDataSource.findReservationById(id);
}

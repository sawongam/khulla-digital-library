// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
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
import 'package:khulla/features/circulation/shared/data/circulation_policy.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';

/// [CirculationRepository] over the local catalogue.
///
/// Orchestration only: each desk write runs in one transaction here so copy
/// status, loan rows, fine snapshots and the reservation queue stay
/// consistent. Row writes live in transaction-scoped helpers sharing this
/// database instance ([CirculationPolicy], [CirculationLoanWrites],
/// [CirculationFineWrites], [CirculationHoldQueue]); list reads delegate to
/// [LoanLocalDataSource], [FineLocalDataSource] and
/// [ReservationLocalDataSource].
@LazySingleton(as: CirculationRepository)
class CirculationRepositoryImpl implements CirculationRepository {
  CirculationRepositoryImpl(
    this._db,
    this._loanDataSource,
    this._fineDataSource,
    this._reservationDataSource,
  );

  final AppDatabase _db;
  final LoanLocalDataSource _loanDataSource;
  final FineLocalDataSource _fineDataSource;
  final ReservationLocalDataSource _reservationDataSource;

  late final _policy = CirculationPolicy(_db);
  late final _loanWrites = CirculationLoanWrites(_db);
  late final _fineWrites = CirculationFineWrites(_db, _policy);
  late final _holdQueue = CirculationHoldQueue(_db, _policy);

  static const String _source = 'CirculationRepositoryImpl';

  @override
  Future<Loan> checkOutCopy({
    required String memberId,
    required String barcode,
    String? staffId,
  }) => guardDatabase(
    () => _db.transaction(
      () => _checkOutCopy(
        memberId: memberId,
        barcode: barcode.trim(),
        staffId: staffId,
      ),
    ),
    source: '$_source.checkOutCopy',
  );

  @override
  Future<List<Loan>> checkOutCopies({
    required String memberId,
    required List<String> barcodes,
    String? staffId,
  }) => guardDatabase(
    () => _db.transaction(() async {
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
    }),
    source: '$_source.checkOutCopies',
  );

  Future<Loan> _checkOutCopy({
    required String memberId,
    required String barcode,
    String? staffId,
  }) async {
    final now = DateTime.now();
    final today = dateOnly(now);

    final copyRow = await (_db.select(
      _db.copies,
    )..where((copy) => copy.barcode.equals(barcode))).getSingleOrNull();
    if (copyRow == null) {
      throw const NotFoundException('No copy matches that barcode.');
    }

    final titleRow = await (_db.select(
      _db.titles,
    )..where((title) => title.id.equals(copyRow.titleId))).getSingleOrNull();
    if (titleRow == null) {
      throw const NotFoundException('The title for that copy was not found.');
    }

    final memberRow = await (_db.select(
      _db.members,
    )..where((member) => member.id.equals(memberId))).getSingleOrNull();
    if (memberRow == null) {
      throw const NotFoundException('That member was not found.');
    }

    final rules = await _policy.loadEffectiveRules(memberRow.memberTypeId);

    _policy.rejectIneligibleMember(
      archivedAt: memberRow.archivedAt,
      suspendedAt: memberRow.suspendedAt,
      expiresAt: memberRow.expiresAt,
      today: today,
    );

    if (copyRow.archivedAt != null) {
      throw const ConflictException('That copy has been archived.');
    }
    if (!titleRow.lendable) {
      throw const ConflictException('That title is not lendable.');
    }
    if (titleRow.archivedAt != null) {
      throw const ConflictException('That title has been archived.');
    }

    if (copyRow.status == CopyStatus.reserved) {
      final readyHold = await _holdQueue.findReadyHoldForCopy(copyRow.id);
      if (readyHold == null || readyHold.memberId != memberId) {
        throw const ConflictException(
          'That copy is reserved for another member.',
        );
      }
    } else if (copyRow.status != CopyStatus.available) {
      throw const ConflictException('That copy is not available to borrow.');
    }

    final openLoans = await _loanDataSource.countOpenLoansForMember(memberId);
    if (openLoans >= rules.borrowingLimit) {
      throw const ConflictException(
        'That member has reached their borrowing limit.',
      );
    }

    if (rules.blockOverdueBorrowers &&
        await _loanDataSource.memberHasOverdueLoans(memberId)) {
      throw const ConflictException(
        'That member has overdue loans and cannot borrow.',
      );
    }

    if (rules.maxOutstandingFine != null) {
      final owed = await _fineDataSource.outstandingForMember(memberId);
      if (owed > rules.maxOutstandingFine!) {
        throw const ConflictException(
          'That member owes more than the allowed outstanding fine.',
        );
      }
    }

    final firstWaiting = await _reservationDataSource
        .findFirstWaitingHoldForTitle(copyRow.titleId);
    if (firstWaiting != null && firstWaiting.memberId != memberId) {
      throw const ConflictException(
        'Another member has an earlier hold on this title.',
      );
    }

    final dueAt = addCalendarDays(today, rules.loanPeriodDays);
    final loanId = await _loanWrites.insertCheckoutLoan(
      copyId: copyRow.id,
      memberId: memberId,
      checkedOutAt: now,
      dueAt: dueAt,
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
    String? staffId,
  }) => guardDatabase(
    () => _db.transaction(
      () => _returnCopy(
        barcode: barcode.trim(),
        condition: condition,
        waiveFine: waiveFine,
        staffId: staffId,
      ),
    ),
    source: '$_source.returnCopy',
  );

  @override
  Future<List<Loan>> returnCopies({
    required List<ReturnCopyInput> copies,
    bool waiveFine = false,
    String? staffId,
  }) => guardDatabase(
    () => _db.transaction(() async {
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
    }),
    source: '$_source.returnCopies',
  );

  Future<Loan> _returnCopy({
    required String barcode,
    required CopyCondition condition,
    required bool waiveFine,
    String? staffId,
  }) async {
    final now = DateTime.now();
    final today = dateOnly(now);

    final copyRow = await (_db.select(
      _db.copies,
    )..where((copy) => copy.barcode.equals(barcode))).getSingleOrNull();
    if (copyRow == null) {
      throw const NotFoundException('No copy matches that barcode.');
    }

    final openLoan = await _loanDataSource.findOpenLoanByCopyId(copyRow.id);
    if (openLoan == null) {
      throw const NotFoundException('That copy is not on loan.');
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
  Future<Loan> renewLoan(String loanId, {String? staffId}) => guardDatabase(
    () => _db.transaction(() => _renewLoan(loanId: loanId)),
    source: '$_source.renewLoan',
  );

  Future<Loan> _renewLoan({required String loanId}) async {
    final loan = await _loanDataSource.findLoanById(loanId);
    if (loan == null) {
      throw const NotFoundException('That loan was not found.');
    }
    if (loan.returnedAt != null) {
      throw const ConflictException('That loan has already been returned.');
    }

    final copyRow = await (_db.select(
      _db.copies,
    )..where((copy) => copy.id.equals(loan.copyId))).getSingleOrNull();
    if (copyRow == null) {
      throw const NotFoundException('The copy for that loan was not found.');
    }

    final rules = await _policy.loadEffectiveRulesForMember(loan.memberId);

    if (loan.renewalCount >= rules.renewalLimit) {
      throw const ConflictException('That loan has reached its renewal limit.');
    }

    final waitingHolds = await _holdQueue.countWaitingHolds(copyRow.titleId);
    if (waitingHolds > 0) {
      throw const ConflictException(
        'A hold is waiting on this title and the loan cannot be renewed.',
      );
    }

    final extendBy = rules.renewalPeriodDays ?? rules.loanPeriodDays;
    await _loanWrites.extendLoanDue(
      loanId: loanId,
      newDueAt: addCalendarDays(loan.dueAt, extendBy),
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
      throw const NotFoundException('That member was not found.');
    }

    final titleRow = await (_db.select(
      _db.titles,
    )..where((title) => title.id.equals(titleId))).getSingleOrNull();
    if (titleRow == null) {
      throw const NotFoundException('That title was not found.');
    }

    final rules = await _policy.loadEffectiveRules(memberRow.memberTypeId);

    _policy.rejectIneligibleMember(
      archivedAt: memberRow.archivedAt,
      suspendedAt: memberRow.suspendedAt,
      expiresAt: memberRow.expiresAt,
      today: today,
    );

    if (titleRow.archivedAt != null) {
      throw const ConflictException('That title has been archived.');
    }
    if (!titleRow.lendable) {
      throw const ConflictException('That title is not lendable.');
    }

    final activeHolds = await _reservationDataSource.countActiveHoldsForMember(
      memberId,
    );
    if (activeHolds >= rules.reservationLimit) {
      throw const ConflictException(
        'That member has reached their hold limit.',
      );
    }

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
    String? staffId,
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

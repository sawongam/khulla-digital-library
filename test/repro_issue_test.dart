// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/catalog/copy/data/local_copy_data_source.dart' as cds;
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/fine/data/local_fine_data_source.dart';
import 'package:khulla/features/circulation/loan/data/local_loan_data_source.dart';
import 'package:khulla/features/circulation/reservation/data/local_reservation_data_source.dart';
import 'package:khulla/features/circulation/shared/data/circulation_repository_impl.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';

import 'helpers/catalog_fixtures.dart';
import 'helpers/test_database.dart';

void main() {
  test('repro return and barcode visibility', () async {
    print('=== Repro Issue 1: Return Copy ===');
    final db = await openTestDatabase();
    final circulation = CirculationRepositoryImpl(
      db,
      LocalLoanDataSource(db),
      LocalFineDataSource(db),
      LocalReservationDataSource(db),
    );
    final copyDS = cds.LocalCopyDataSource(db);

    final ref = await seedReferenceData(db);
    final barcodes = ['KH-1', 'KH-10', 'KH-11', 'KH-12', 'KH-13', 'KH-14', 'KH-15'];
    final member = await seedMember(db, memberTypeId: ref.memberTypeId, cardNumber: 'MEM-RET');
    for (var i = 0; i < barcodes.length; i++) {
      final s = await seedTitleWithCopy(db, formatId: ref.formatId, barcode: barcodes[i], title: 'Title $i');
      // ignore unused
    }
    print('Checking out KH-1 to member ${member.memberId}');
    final loan = await circulation.checkOutCopy(memberId: member.memberId, barcode: 'KH-1');
    print('Checkout loan: barcode=${loan.barcode}, copyId=${loan.copyId}, id=${loan.id}');

    print('\n--- Simulating ReturnCubit.addLoanByBarcode with search KH-1 limit 5 ---');
    final result = await circulation.findOpenLoans(LoanQuery(search: 'KH-1', limit: 5));
    print('Found ${result.items.length} items, total ${result.totalCount}');
    for (var l in result.items) {
      print('  - barcode=${l.barcode} title=${l.titleName}');
    }
    String trimmed = 'KH-1';
    dynamic foundLoan;
    for (final item in result.items) {
      if (item.barcode?.toLowerCase() == trimmed.toLowerCase()) {
        foundLoan = item;
        break;
      }
    }
    foundLoan ??= result.items.length == 1 ? result.items.first : null;
    print('ReturnCubit foundLoan: ${foundLoan?.barcode ?? "null"} -> Would toss NotFound if null?');

    print('\n--- Search KH-10 ---');
    final result10 = await circulation.findOpenLoans(LoanQuery(search: 'KH-10', limit: 5));
    print('Found ${result10.items.length}: ${result10.items.map((l) => l.barcode).toList()}');

    await updateLoanRules(db, borrowingLimit: 10);
    for (var i = 1; i < barcodes.length; i++) {
      try {
        await circulation.checkOutCopy(memberId: member.memberId, barcode: barcodes[i]);
        print('Checked out ${barcodes[i]}');
      } catch (e) {
        print('Checkout ${barcodes[i]} failed: $e');
      }
    }
    print('\n--- After checking out all 7, search KH-1 limit 5 again ---');
    final resultAfter = await circulation.findOpenLoans(LoanQuery(search: 'KH-1', limit: 5));
    print('Found ${resultAfter.items.length} of total ${resultAfter.totalCount}: ${resultAfter.items.map((l) => l.barcode).toList()}');
    print('If KH-1 is oldest, it would be last and not in limit 5 -> BUG!');

    final copyRows = await (db.select(db.copies)..where((c) => c.barcode.equals('KH-1'))).get();
    final copyId = copyRows.first.id;
    final openLoanByCopy = await LocalLoanDataSource(db).findOpenLoanByCopyId(copyId);
    print('Direct findOpenLoanByCopyId for KH-1: ${openLoanByCopy?.barcode ?? "null"}');

    print('\n--- Attempting returnCopy KH-1 via repository ---');
    try {
      final returned = await circulation.returnCopy(barcode: 'KH-1', condition: CopyCondition.good);
      print('Return success: loan id ${returned.id} returnedAt ${returned.returnedAt}');
    } catch (e) {
      print('Return failed: $e');
    }

    final copyAfter = await (db.select(db.copies)..where((c) => c.barcode.equals('KH-1'))).getSingle();
    print('Copy status after return: ${copyAfter.status}');

    print('\n=== Repro Issue 2: Book Number visibility ===');
    final seeded = await seedTitleWithCopy(db, formatId: ref.formatId, barcode: 'BOOK-001', title: 'Visible Test Title');
    print('Created copy BOOK-001 with titleId ${seeded.titleId}');
    final mem2 = await seedMember(db, memberTypeId: ref.memberTypeId, cardNumber: 'MEM-VIS');
    final loan2 = await circulation.checkOutCopy(memberId: mem2.memberId, barcode: 'BOOK-001');
    print('Checked out BOOK-001 loan barcode=${loan2.barcode}');

    final copies = await copyDS.findCopiesByTitleId(seeded.titleId);
    print('Copies for title after checkout (should show BOOK-001): count ${copies.length}');
    for (var c in copies) {
      print('  copy barcode=${c.barcode} status=${c.status} borrower=${c.borrower} due=${c.dueAt}');
    }

    final history = await circulation.findLoans(LoanQuery(titleId: seeded.titleId));
    print('\nLoan history for titleId (all loans): total ${history.totalCount} items ${history.items.length}');
    for (var l in history.items) {
      print('  loan barcode=${l.barcode} returnedAt=${l.returnedAt} member=${l.memberName}');
    }

    final returnedOnly = history.items.where((l) => l.returnedAt != null).toList();
    print('Returned only (as TitleDetailCubit history): ${returnedOnly.length}');
    print('Open loan barcode visible in copies? ${copies.any((c) => c.barcode == "BOOK-001") ? "YES" : "NO"}');
    print('\nTitleHistoryCard barcode column showFrom expanded -> hidden on phone => Book Number not visible on mobile?');

    await closeTestDatabase(db);
  });
}

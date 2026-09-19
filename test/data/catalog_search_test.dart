// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/data/local_title_data_source.dart';
import 'package:khulla/features/catalog/title/data/title_repository_impl.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/features/members/data/local_member_data_source.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// Title and member list queries: search through the FTS5 indexes and the
/// triggers that keep them current, and the per-row counts beside it.
void main() {
  late AppDatabase db;
  late TitleRepositoryImpl titles;
  late LocalMemberDataSource members;
  late ReferenceSeed reference;

  setUp(() async {
    db = await openTestDatabase();
    titles = TitleRepositoryImpl(LocalTitleDataSource(db));
    members = LocalMemberDataSource(db);
    reference = await seedReferenceData(db);
  });

  tearDown(() => closeTestDatabase(db));

  Future<String> saveTitle(String title, String author, {String? id}) async {
    final saved = await titles.saveTitle(
      id: id,
      title: title,
      author: author,
      formatId: reference.formatId,
      lendable: true,
      replacementCost: Money.zero,
    );
    return saved.id;
  }

  Future<List<String>> searchTitles(String search) async {
    final result = await titles.findTitles(
      TitleQuery(search: search, limit: 50),
    );
    return [for (final title in result.items) title.title];
  }

  Future<List<String>> searchMembers(String search) async {
    final result = await members.findMembers(
      MemberQuery(search: search, limit: 50),
    );
    return [for (final member in result.items) member.fullName];
  }

  group('title search', () {
    test('finds a substring inside a word', () async {
      await saveTitle('Harry Potter', 'J.K. Rowling');
      await saveTitle('Muna Madan', 'Laxmi Prasad Devkota');

      expect(await searchTitles('otte'), ['Harry Potter']);
    });

    test('needs every term, from any field, in any order', () async {
      await saveTitle('Harry Potter', 'J.K. Rowling');
      await saveTitle('The Casual Vacancy', 'J.K. Rowling');
      await saveTitle("The Potter's Hand", 'A. N. Other');

      expect(await searchTitles('rowling potter'), ['Harry Potter']);
    });

    test('matches terms shorter than a trigram', () async {
      await saveTitle('Harry Potter', 'J.K. Rowling');
      await saveTitle('Muna Madan', 'Laxmi Prasad Devkota');

      expect(await searchTitles('po'), ['Harry Potter']);
      expect(await searchTitles('harry po'), ['Harry Potter']);
    });

    test('finds Nepali text inside a word', () async {
      await saveTitle('मुना मदन', 'लक्ष्मीप्रसाद देवकोटा');
      await saveTitle('Harry Potter', 'J.K. Rowling');

      expect(await searchTitles('देवको'), ['मुना मदन']);
      expect(await searchTitles('प्रसाद'), ['मुना मदन']);
    });

    test('ignores case and Latin diacritics', () async {
      await saveTitle('José Rizal', 'Unknown');

      expect(await searchTitles('JOSE'), ['José Rizal']);
    });

    test('reads query syntax and LIKE wildcards as plain text', () async {
      await saveTitle('Harry Potter', 'J.K. Rowling');

      expect(await searchTitles('potter NOT'), isEmpty);
      expect(await searchTitles('"potter'), isEmpty);
      expect(await searchTitles('%'), isEmpty);
      expect(await searchTitles('_'), isEmpty);
    });

    test('follows edits, deletes and archiving', () async {
      final id = await saveTitle('Harry Potter', 'J.K. Rowling');
      await saveTitle('Goblet of Fire', 'J.K. Rowling', id: id);

      expect(await searchTitles('potter'), isEmpty);
      expect(await searchTitles('goblet'), ['Goblet of Fire']);

      await titles.removeTitle(id);
      expect(await searchTitles('goblet'), isEmpty);

      final archived = await saveTitle('Muna Madan', 'Devkota');
      await titles.archiveTitle(archived);
      expect(await searchTitles('muna'), isEmpty);
    });
  });

  group('title counts', () {
    test('count live copies and filter on availability', () async {
      final seeded = await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        title: 'Counted',
      );
      await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        title: 'Other',
        barcode: 'TEST-002',
      );

      var result = await titles.findTitles(
        const TitleQuery(search: 'counted', availableOnly: true),
      );
      expect(result.totalCount, 1);
      expect(result.items.single.copyCount, 1);
      expect(result.items.single.availableCount, 1);

      await (db.update(db.copies)
            ..where((copy) => copy.id.equals(seeded.copyId)))
          .write(const CopiesCompanion(status: Value(CopyStatus.onLoan)));

      result = await titles.findTitles(
        const TitleQuery(search: 'counted', availableOnly: true),
      );
      expect(result.totalCount, 0);
      expect(result.items, isEmpty);

      final title = await titles.findTitle(seeded.titleId);
      expect(title!.copyCount, 1);
      expect(title.availableCount, 0);
    });
  });

  group('member search', () {
    test('finds a member by part of a name or card number', () async {
      await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        barcode: 'KH-000123',
        fullName: 'Sita Sharma',
      );
      await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        barcode: 'KH-000456',
        fullName: 'Ram Thapa',
      );

      expect(await searchMembers('0123'), ['Sita Sharma']);
      expect(await searchMembers('thap'), ['Ram Thapa']);
      expect(await searchMembers('12'), ['Sita Sharma']);
    });

    test('follows a rename', () async {
      final seeded = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        fullName: 'Sita Sharma',
      );
      await (db.update(db.members)
            ..where((member) => member.id.equals(seeded.memberId)))
          .write(const MembersCompanion(fullName: Value('Gita Karki')));

      expect(await searchMembers('sharma'), isEmpty);
      expect(await searchMembers('karki'), ['Gita Karki']);
    });
  });

  group('member counts', () {
    test('count open, overdue and all-time loans and money owed', () async {
      final borrower = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        fullName: 'Borrower',
      );
      await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        barcode: 'MEM-002',
        fullName: 'Idle',
      );
      final first = await seedTitleWithCopy(db, formatId: reference.formatId);
      final second = await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        barcode: 'TEST-002',
      );

      final now = DateTime.now();
      Future<void> insertLoan(
        String id,
        String copyId, {
        required DateTime dueAt,
        DateTime? returnedAt,
      }) => db
          .into(db.loans)
          .insert(
            LoansCompanion.insert(
              id: id,
              copyId: copyId,
              memberId: borrower.memberId,
              checkedOutAt: now.subtract(const Duration(days: 20)),
              dueAt: dueAt,
              returnedAt: Value(returnedAt),
              ruleLoanPeriodDays: 14,
              ruleFinePerDay: Money.major(5),
              ruleGraceDays: 1,
              ruleMaximumFine: Money.major(500),
              createdAt: now,
            ),
          );

      await insertLoan(
        'overdue',
        first.copyId,
        dueAt: now.subtract(const Duration(days: 6)),
      );
      await insertLoan(
        'returned',
        second.copyId,
        dueAt: now.subtract(const Duration(days: 6)),
        returnedAt: now,
      );
      await db
          .into(db.fines)
          .insert(
            FinesCompanion.insert(
              id: 'fine',
              memberId: borrower.memberId,
              loanId: const Value('returned'),
              reason: FineReason.overdue,
              assessed: Money.major(50),
              paid: Value(Money.major(20)),
              raisedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final member = await members.findMemberById(borrower.memberId);
      expect(member!.loansOut, 1);
      expect(member.overdueLoans, 1);
      expect(member.borrowedAllTime, 2);
      expect(member.finesOwed, Money.major(30));

      final withLoans = await members.findMembers(
        const MemberQuery(withLoans: true),
      );
      expect(withLoans.totalCount, 1);
      expect(withLoans.items.single.fullName, 'Borrower');

      final owing = await members.findMembers(
        const MemberQuery(owesFines: true, search: 'borrow'),
      );
      expect(owing.items.single.finesOwed, Money.major(30));
    });
  });

  test('a hold cannot be open by status and closed by date', () async {
    final title = await seedTitleWithCopy(db, formatId: reference.formatId);
    final member = await seedMember(db, memberTypeId: reference.memberTypeId);
    final now = DateTime.now();

    expect(
      () => db
          .into(db.reservations)
          .insert(
            ReservationsCompanion.insert(
              id: 'hold',
              titleId: title.titleId,
              memberId: member.memberId,
              placedAt: now,
              status: ReservationStatus.waiting,
              closedAt: Value(now),
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}

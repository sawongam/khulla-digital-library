// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/core/database/converters/money_converter.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// Drift type converters round-trip through SQL, not just in isolation.
///
/// Each group checks the converter directly and through a real column write,
/// because drift code generation is where the mapping actually lands.
void main() {
  group('MoneyConverter', () {
    const converter = MoneyConverter();

    test('roundtrips minor units', () {
      final amount = Money.major(12.50);
      expect(converter.fromSql(converter.toSql(amount)), amount);
    });

    test('roundtrips through a drift column', () async {
      final db = await openTestDatabase();
      try {
        await db
            .into(db.loanRules)
            .insert(
              LoanRulesCompanion.insert(
                finePerDay: Value(Money.major(3)),
                updatedAt: DateTime.now(),
              ),
            );

        final row = await db.select(db.loanRules).getSingle();
        expect(row.finePerDay, Money.major(3));
      } finally {
        await closeTestDatabase(db);
      }
    });
  });

  group('DateOnlyConverter', () {
    const converter = DateOnlyConverter();

    test('roundtrips YYYY-MM-DD unchanged', () {
      final date = DateTime(2024, 6, 15);
      final sql = converter.toSql(date);
      expect(sql, '2024-06-15');
      expect(dateOnly(converter.fromSql(sql)), dateOnly(date));
    });

    test('uses calendar date, not clock time', () {
      final lateEvening = DateTime(2024, 6, 15, 23, 45);
      expect(converter.toSql(lateEvening), '2024-06-15');
      expect(
        dateOnly(converter.fromSql(converter.toSql(lateEvening))),
        dateOnly(lateEvening),
      );
    });

    test('roundtrips through a drift column', () async {
      final db = await openTestDatabase();
      try {
        final reference = await seedReferenceData(db);
        final member = await seedMember(
          db,
          memberTypeId: reference.memberTypeId,
          barcode: 'DATE-MEM',
        );
        final expires = DateTime(2025, 1, 20);

        await (db.update(db.members)
              ..where((m) => m.id.equals(member.memberId)))
            .write(MembersCompanion(expiresAt: Value(expires)));

        final row = await (db.select(
          db.members,
        )..where((m) => m.id.equals(member.memberId))).getSingle();
        expect(row.expiresAt, isNotNull);
        expect(dateOnly(row.expiresAt!), dateOnly(expires));
      } finally {
        await closeTestDatabase(db);
      }
    });
  });
}

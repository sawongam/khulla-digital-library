// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:country_phone_kit/country_phone_kit.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.steps.dart';
import 'package:khulla/core/database/connection.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/core/database/converters/money_converter.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/copy/data/tables/copies.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/data/tables/title_formats.dart';
import 'package:khulla/features/catalog/title/data/tables/titles.dart';
import 'package:khulla/features/circulation/fine/data/tables/fines.dart';
import 'package:khulla/features/circulation/loan/data/tables/loans.dart';
import 'package:khulla/features/circulation/reservation/data/tables/reservations.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/features/members/data/tables/member_types.dart';
import 'package:khulla/features/members/data/tables/members.dart';
import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/settings/data/tables/library_settings.dart';
import 'package:khulla/features/settings/data/tables/loan_rules.dart';
import 'package:khulla/features/users/data/tables/staff.dart';
import 'package:khulla/features/users/data/tables/staff_recovery_codes.dart';
// The enums the tables store through `textEnum` are named in the generated
// part file, which cannot carry imports of its own — they have to be visible
// from here even though nothing in this file mentions them.
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';

part 'app_database.g.dart';

/// Owns the single SQLite connection for the app's lifetime.
@lazySingleton
@DriftDatabase(
  tables: [
    LibrarySettings,
    Staff,
    StaffRecoveryCodes,
    LoanRules,
    TitleFormats,
    MemberTypes,
    Titles,
    Copies,
    Members,
    Loans,
    Fines,
    Reservations,
  ],
  // FTS5 search indexes and the triggers that fill them — virtual tables and
  // triggers can only be declared in SQL.
  include: {
    'package:khulla/features/catalog/title/data/tables/titles_fts.drift',
    'package:khulla/features/members/data/tables/members_fts.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(AppConfig config) : super(openDatabaseConnection(config));

  @visibleForTesting
  AppDatabase.connect(super.e);

  static const String _source = 'AppDatabase';

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: _createSchema,
    onUpgrade: _upgradeSchema,
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> warmUp() => customSelect('SELECT 1').get();

  /// Runs [action] in a transaction, then makes sure its commit reaches the
  /// browser's storage.
  ///
  /// On web, drift keeps the database in memory and copies it to IndexedDB
  /// after each statement that runs outside a transaction. The `COMMIT` itself
  /// still counts as inside one — drift clears the flag only after it — so a
  /// committed transaction stays in memory until some later plain write
  /// happens to copy it. A refresh before that loses it: onboarding's
  /// administrator vanished this way, and so would a checkout.
  ///
  /// The no-op statement after the commit runs with the flag clear, which is
  /// what triggers the copy. Inside an outer transaction it joins that one and
  /// does nothing, and on native it is one trivial statement.
  @override
  Future<T> transaction<T>(
    Future<T> Function() action, {
    bool requireNew = false,
  }) async {
    final result = await super.transaction(action, requireNew: requireNew);
    await customStatement('SELECT 1');
    return result;
  }

  @disposeMethod
  Future<void> dispose() => close();

  Future<void> _createSchema(Migrator m) async {
    AppLogger.info(
      'Creating catalogue schema v$schemaVersion',
      source: _source,
    );
    await m.createAll();
  }

  Future<void> _upgradeSchema(Migrator m, int from, int to) async {
    if (from > to) {
      AppLogger.error(
        'Catalogue schema v$from is newer than this build expects (v$to). '
        'Refusing to open so no data is lost.',
        source: _source,
        fatal: true,
      );
      throw const DatabaseUnavailableException(
        'This library file was created by a newer version of Khulla Digital Library.',
      );
    }

    AppLogger.info('Migrating catalogue from v$from to v$to', source: _source);

    await stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.librarySettings);
        await m.createTable(schema.staff);
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.loanRules);
        await m.createTable(schema.titleFormats);
        await m.createTable(schema.memberTypes);
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.branch,
        );
        await m.addColumn(schema.librarySettings, schema.librarySettings.email);
        await m.addColumn(schema.librarySettings, schema.librarySettings.phone);
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.address,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.openingHours,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.barcodePrefix,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.barcodeNextValue,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.updatedAt,
        );
      },
      from3To4: (m, schema) async {
        // v3 snapshot recorded inline column checks on loan_rules that the
        // current table no longer declares — recreate so v4 matches the snapshot.
        await m.deleteTable('loan_rules');
        await m.createTable(schema.loanRules);
        await m.createTable(schema.titles);
        await m.createTable(schema.copies);
        await m.createIndex(
          Index(
            'titles_search',
            'CREATE INDEX titles_search ON titles (search_text)',
          ),
        );
        await m.createIndex(
          Index(
            'titles_format',
            'CREATE INDEX titles_format ON titles (format_id)',
          ),
        );
        await m.createIndex(
          Index('titles_sort', 'CREATE INDEX titles_sort ON titles (title)'),
        );
        await m.createIndex(
          Index(
            'titles_isbn',
            'CREATE INDEX titles_isbn ON titles (isbn) WHERE isbn IS NOT NULL',
          ),
        );
        await m.createIndex(
          Index(
            'copies_barcode',
            'CREATE UNIQUE INDEX copies_barcode ON copies (barcode)',
          ),
        );
        await m.createIndex(
          Index(
            'copies_title',
            'CREATE INDEX copies_title ON copies (title_id)',
          ),
        );
        await m.createIndex(
          Index(
            'copies_status',
            'CREATE INDEX copies_status ON copies (status) WHERE archived_at IS NULL',
          ),
        );
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.members);
        await m.createIndex(
          Index(
            'members_card',
            'CREATE UNIQUE INDEX members_card ON members (card_number)',
          ),
        );
        await m.createIndex(
          Index(
            'members_search',
            'CREATE INDEX members_search ON members (search_text)',
          ),
        );
        await m.createIndex(
          Index(
            'members_type',
            'CREATE INDEX members_type ON members (member_type_id)',
          ),
        );
        await m.createIndex(
          Index(
            'members_expiry',
            'CREATE INDEX members_expiry ON members (expires_at) WHERE archived_at IS NULL',
          ),
        );
      },
      from5To6: (m, schema) async {
        await m.createTable(schema.loans);
        await m.createTable(schema.fines);
        await m.createTable(schema.reservations);
        await m.createIndex(
          Index(
            'loans_one_open_per_copy',
            'CREATE UNIQUE INDEX loans_one_open_per_copy ON loans (copy_id) WHERE returned_at IS NULL',
          ),
        );
        await m.createIndex(
          Index(
            'loans_open_by_member',
            'CREATE INDEX loans_open_by_member ON loans (member_id) WHERE returned_at IS NULL',
          ),
        );
        await m.createIndex(
          Index(
            'loans_due',
            'CREATE INDEX loans_due ON loans (due_at) WHERE returned_at IS NULL',
          ),
        );
        await m.createIndex(
          Index(
            'loans_member_history',
            'CREATE INDEX loans_member_history ON loans (member_id, checked_out_at DESC)',
          ),
        );
        await m.createIndex(
          Index(
            'loans_copy_history',
            'CREATE INDEX loans_copy_history ON loans (copy_id, checked_out_at DESC)',
          ),
        );
        await m.createIndex(
          Index(
            'fines_outstanding',
            'CREATE INDEX fines_outstanding ON fines (member_id) WHERE paid + waived < assessed',
          ),
        );
        await m.createIndex(
          Index(
            'reservations_one_active_per_member_title',
            'CREATE UNIQUE INDEX reservations_one_active_per_member_title '
                'ON reservations (title_id, member_id) WHERE closed_at IS NULL',
          ),
        );
        await m.createIndex(
          Index(
            'reservations_queue',
            'CREATE INDEX reservations_queue ON reservations (title_id, placed_at) '
                'WHERE closed_at IS NULL',
          ),
        );
      },
      from6To7: (m, schema) async {
        await m.createTable(schema.staffRecoveryCodes);
        await m.createIndex(schema.staffRecoveryCodesStaff);
      },
      from7To8: (m, schema) async {},
      from8To9: (m, schema) async {
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.currencyName,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.currencySymbol,
        );

        final rows = await customSelect(
          'SELECT currency FROM library_settings',
        ).get();
        for (final row in rows) {
          final code = row.read<String>('currency');
          final kit = Currencies.byCode(code);
          if (kit == null) continue;
          await customStatement(
            'UPDATE library_settings '
            'SET currency_name = ?, currency_symbol = ? '
            'WHERE currency = ?',
            [kit.name, kit.symbol, code],
          );
        }
      },
      from9To10: (m, schema) async {
        await m.dropColumn(schema.librarySettings, 'branch');
        await m.dropColumn(schema.titles, 'subtitle');
        await m.dropColumn(schema.titles, 'subjects');
      },
      from10To11: (m, schema) async {
        await m.dropColumn(schema.copies, 'condition');
      },
      from11To12: (m, schema) async {
        // Search moves from a hand-built `search_text` column, read with a
        // leading-wildcard LIKE no index can serve, to FTS5 tables that
        // triggers keep in step. The trigger SQL is written out here rather
        // than taken from the live database, so this step stays what v12 was.
        await customStatement('DROP INDEX titles_search');
        await customStatement('DROP INDEX members_search');
        await m.dropColumn(schema.titles, 'search_text');
        await m.dropColumn(schema.members, 'search_text');
        await m.create(schema.titlesFts);
        await m.create(schema.membersFts);
        for (final statement in _v12SearchTriggers) {
          await customStatement(statement);
        }
        await customStatement(
          'INSERT INTO titles_fts (rowid, title, author, isbn, publisher, shelf) '
          'SELECT rowid, title, author, isbn, publisher, shelf FROM titles',
        );
        await customStatement(
          'INSERT INTO members_fts '
          '(rowid, full_name, card_number, email, phone, address, guardian) '
          'SELECT rowid, full_name, card_number, email, phone, address, guardian '
          'FROM members',
        );

        // Two indexes widen under their old names; the rest are new.
        await customStatement('DROP INDEX copies_title');
        await m.createIndex(schema.copiesTitle);
        await customStatement('DROP INDEX loans_open_by_member');
        await m.createIndex(schema.loansOpenByMember);
        await m.createIndex(schema.loansCheckedOut);
        await m.createIndex(schema.loansReturned);
        await m.createIndex(schema.finesMember);
        await m.createIndex(schema.finesRaised);

        // Reconcile holds whose status and closed_at disagree before the
        // CHECK refuses them. Both fixes close the hold, never reopen one, so
        // neither can collide with the one-open-hold-per-member index.
        await customStatement(
          'UPDATE reservations SET closed_at = updated_at '
          "WHERE closed_at IS NULL AND status NOT IN ('waiting', 'ready')",
        );
        await customStatement(
          "UPDATE reservations SET status = 'cancelled' "
          "WHERE closed_at IS NOT NULL AND status IN ('waiting', 'ready')",
        );
        await m.alterTable(TableMigration(schema.reservations));
        await m.createIndex(schema.reservationsMember);
      },
      from12To13: (m, schema) async {
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.logoRef,
        );
      },
      from13To14: (m, schema) async {
        await customStatement(
          'ALTER TABLE members RENAME COLUMN card_number TO barcode',
        );
        await customStatement('DROP INDEX IF EXISTS members_card');
        await m.createIndex(schema.membersBarcode);
        await m.addColumn(schema.members, schema.members.gender);
        await m.addColumn(schema.members, schema.members.bloodGroup);
        await m.addColumn(schema.members, schema.members.municipality);
        await m.addColumn(schema.members, schema.members.occupation);
        await m.addColumn(schema.members, schema.members.institution);
        await m.addColumn(schema.members, schema.members.idVerification);
        await m.addColumn(
          schema.members,
          schema.members.emergencyContactName,
        );
        await m.addColumn(
          schema.members,
          schema.members.emergencyContactPhone,
        );
        await customStatement('DROP TRIGGER IF EXISTS members_fts_insert');
        await customStatement('DROP TRIGGER IF EXISTS members_fts_update');
        await customStatement('DROP TRIGGER IF EXISTS members_fts_delete');
        await customStatement('DROP TABLE IF EXISTS members_fts');
        await m.create(schema.membersFts);
        for (final statement in _v14SearchTriggers) {
          await customStatement(statement);
        }
        await customStatement(
          'INSERT INTO members_fts (rowid, full_name, barcode, email, phone, address, municipality, occupation, institution, id_verification, emergency_contact_name, guardian) '
          'SELECT rowid, full_name, barcode, email, phone, address, municipality, occupation, institution, id_verification, emergency_contact_name, guardian FROM members',
        );
      },
      from14To15: (m, schema) async {
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.memberBarcodePrefix,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.memberBarcodeNextValue,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.staffBarcodePrefix,
        );
        await m.addColumn(
          schema.librarySettings,
          schema.librarySettings.staffBarcodeNextValue,
        );
        await m.addColumn(schema.staff, schema.staff.barcode);
        await m.createIndex(schema.staffBarcode);
        // Backfill existing staff with generated barcodes.
        final settingsRow = await customSelect(
          'SELECT staff_barcode_prefix, staff_barcode_next_value FROM library_settings WHERE id = 1',
        ).getSingleOrNull();
        if (settingsRow != null) {
          final prefix = settingsRow.read<String>('staff_barcode_prefix');
          var next = settingsRow.read<int>('staff_barcode_next_value');
          final staffRows = await customSelect(
            'SELECT id FROM staff WHERE barcode IS NULL ORDER BY created_at',
          ).get();
          for (final row in staffRows) {
            final id = row.read<String>('id');
            final barcode = '$prefix$next';
            await customStatement(
              'UPDATE staff SET barcode = ? WHERE id = ?',
              [barcode, id],
            );
            next++;
          }
          await customStatement(
            'UPDATE library_settings SET staff_barcode_next_value = ? WHERE id = 1',
            [next],
          );
        }
      },
    )(m, from, to);
  }
}

/// The v12 search triggers, exactly as `titles_fts.drift` and
/// `members_fts.drift` declared them when `from11To12` shipped. They are frozen
/// with that step: a later change to those files ships as a later migration.
const List<String> _v12SearchTriggers = [
  '''
CREATE TRIGGER titles_fts_insert AFTER INSERT ON titles BEGIN
  INSERT INTO titles_fts (rowid, title, author, isbn, publisher, shelf)
  VALUES (new.rowid, new.title, new.author, new.isbn, new.publisher, new.shelf);
END;''',
  '''
CREATE TRIGGER titles_fts_update
AFTER UPDATE OF title, author, isbn, publisher, shelf ON titles BEGIN
  UPDATE titles_fts
  SET title = new.title,
      author = new.author,
      isbn = new.isbn,
      publisher = new.publisher,
      shelf = new.shelf
  WHERE rowid = old.rowid;
END;''',
  '''
CREATE TRIGGER titles_fts_delete AFTER DELETE ON titles BEGIN
  DELETE FROM titles_fts WHERE rowid = old.rowid;
END;''',
  '''
CREATE TRIGGER members_fts_insert AFTER INSERT ON members BEGIN
  INSERT INTO members_fts (rowid, full_name, card_number, email, phone, address, guardian)
  VALUES (new.rowid, new.full_name, new.card_number, new.email, new.phone, new.address, new.guardian);
END;''',
  '''
CREATE TRIGGER members_fts_update
AFTER UPDATE OF full_name, card_number, email, phone, address, guardian ON members BEGIN
  UPDATE members_fts
  SET full_name = new.full_name,
      card_number = new.card_number,
      email = new.email,
      phone = new.phone,
      address = new.address,
      guardian = new.guardian
  WHERE rowid = old.rowid;
END;''',
  '''
CREATE TRIGGER members_fts_delete AFTER DELETE ON members BEGIN
  DELETE FROM members_fts WHERE rowid = old.rowid;
END;''',
];

/// The v14 member search triggers — `members_fts` now indexes the richer
/// profile (barcode, municipality, occupation, institution, id verification
/// and emergency contact) alongside the name and contacts.
const List<String> _v14SearchTriggers = [
  '''
CREATE TRIGGER members_fts_insert AFTER INSERT ON members BEGIN
  INSERT INTO members_fts (rowid, full_name, barcode, email, phone, address, municipality, occupation, institution, id_verification, emergency_contact_name, guardian)
  VALUES (new.rowid, new.full_name, new.barcode, new.email, new.phone, new.address, new.municipality, new.occupation, new.institution, new.id_verification, new.emergency_contact_name, new.guardian);
END;''',
  '''
CREATE TRIGGER members_fts_update
AFTER UPDATE OF full_name, barcode, email, phone, address, municipality, occupation, institution, id_verification, emergency_contact_name, guardian ON members BEGIN
  UPDATE members_fts
  SET full_name = new.full_name,
      barcode = new.barcode,
      email = new.email,
      phone = new.phone,
      address = new.address,
      municipality = new.municipality,
      occupation = new.occupation,
      institution = new.institution,
      id_verification = new.id_verification,
      emergency_contact_name = new.emergency_contact_name,
      guardian = new.guardian
  WHERE rowid = old.rowid;
END;''',
  '''
CREATE TRIGGER members_fts_delete AFTER DELETE ON members BEGIN
  DELETE FROM members_fts WHERE rowid = old.rowid;
END;''',
];

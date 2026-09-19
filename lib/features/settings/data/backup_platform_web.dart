// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Table, TableInfo, VirtualTableInfo;
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';

/// Every table a backup carries. Search indexes (`titles_fts`,
/// `members_fts`) are left out: restoring the tables they index fires the
/// triggers that rebuild them, so a dumped copy would only be written twice.
Iterable<TableInfo<Table, Object?>> _backedUpTables(AppDatabase db) =>
    db.allTables.where((table) => table is! VirtualTableInfo);

/// Dumps every table to one JSON document — there is no file to copy on
/// web, only the OPFS/IndexedDB store behind [db]'s own connection, so the
/// export goes through that connection instead of the filesystem.
Future<Uint8List> exportBackupBytes(AppDatabase db, AppConfig config) async {
  final tables = <String, List<Map<String, Object?>>>{};
  // One consistent snapshot: without the transaction a concurrent write
  // between two tables' SELECTs could export a torn state.
  await db.transaction(() async {
    for (final table in _backedUpTables(db)) {
      final rows = await db
          .customSelect('SELECT * FROM ${table.actualTableName}')
          .get();
      tables[table.actualTableName] = [for (final row in rows) row.data];
    }
  });

  final dump = <String, Object?>{
    'schemaVersion': db.schemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'tables': tables,
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(dump)));
}

/// Replaces every row in every table with what [bytes] holds, inside one
/// transaction with foreign-key checks suspended — table order does not
/// matter when nothing is being checked against it, which is what makes a
/// fully generic restore possible without a hand-written table order.
Future<void> importBackupBytes(
  AppDatabase db,
  AppConfig config,
  Uint8List bytes,
) async {
  final Map<String, Object?> decoded;
  try {
    final parsed = jsonDecode(utf8.decode(bytes));
    if (parsed is! Map<String, Object?>) {
      throw const InvalidInputException('That file is not a Khulla backup.');
    }
    decoded = parsed;
  } on FormatException {
    throw const InvalidInputException('That file is not a Khulla backup.');
  }

  final schemaVersion = decoded['schemaVersion'];
  final tables = decoded['tables'];
  if (schemaVersion is! int ||
      tables is! Map ||
      schemaVersion != db.schemaVersion) {
    throw const InvalidInputException(
      'That backup does not match this app version.',
    );
  }

  // The backup file controls these identifiers, so allowlist them against
  // the schema before interpolating into SQL — otherwise a crafted file
  // injects arbitrary statements through table/column names.
  final expectedTables = {
    for (final table in _backedUpTables(db)) table.actualTableName,
  };
  final backupKeys = <String>{};
  for (final key in tables.keys) {
    if (key is! String) {
      throw const InvalidInputException(
        'That file is not a Khulla backup.',
      );
    }
    backupKeys.add(key);
  }
  if (backupKeys.length != expectedTables.length ||
      !backupKeys.containsAll(expectedTables)) {
    throw const InvalidInputException(
      'That backup does not match this app version.',
    );
  }
  final identifier = RegExp(r'^[a-z_][a-z0-9_]*$');
  for (final entry in tables.entries) {
    final key = entry.key;
    if (key is! String ||
        !expectedTables.contains(key) ||
        !identifier.hasMatch(key)) {
      throw const InvalidInputException(
        'That file is not a Khulla backup.',
      );
    }
    final value = entry.value;
    if (value is! List) {
      throw const InvalidInputException(
        'That file is not a Khulla backup.',
      );
    }
    for (final element in value) {
      if (element is! Map) {
        throw const InvalidInputException(
          'That file is not a Khulla backup.',
        );
      }
      for (final column in element.keys) {
        if (column is! String || !identifier.hasMatch(column)) {
          throw const InvalidInputException(
            'That file is not a Khulla backup.',
          );
        }
      }
    }
  }

  await db.customStatement('PRAGMA foreign_keys = OFF');
  try {
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.customStatement('DELETE FROM ${table.actualTableName}');
      }
      for (final entry in tables.entries) {
        final rows = (entry.value as List).cast<Map<String, Object?>>();
        for (final row in rows) {
          final columns = row.keys.toList();
          final placeholders = List.filled(columns.length, '?').join(', ');
          await db.customStatement(
            'INSERT INTO ${entry.key} (${columns.join(', ')}) '
            'VALUES ($placeholders)',
            [for (final column in columns) row[column]],
          );
        }
      }
    });
  } finally {
    await db.customStatement('PRAGMA foreign_keys = ON');
  }
}

/// Nothing to size or locate — the store is inside the browser profile, not
/// at a path this app can read.
Future<({int? sizeBytes, String? path})> inspectStorage(AppConfig config) =>
    Future.value((sizeBytes: null, path: null));

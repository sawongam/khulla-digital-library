// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';

/// Records the commits and custom statements an [AppDatabase] issues, and
/// whether each statement ran inside a transaction.
class _StatementRecorder extends QueryInterceptor {
  final List<String> events = [];

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await inner.send();
    events.add('COMMIT');
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement == 'SELECT 1') {
      events.add(
        executor is TransactionExecutor ? 'SELECT 1 (in tx)' : 'SELECT 1',
      );
    }
    return executor.runCustom(statement, args);
  }
}

/// The web build only copies a commit to IndexedDB when a statement runs
/// after it outside any transaction. There is no IndexedDB under `flutter
/// test`, so this pins the statement that triggers the copy rather than the
/// copy itself.
void main() {
  late _StatementRecorder recorder;
  late AppDatabase db;

  setUp(() async {
    recorder = _StatementRecorder();
    db = AppDatabase.connect(NativeDatabase.memory().interceptWith(recorder));
    await db.warmUp();
    recorder.events.clear();
  });

  tearDown(() => db.close());

  test('runs a statement outside the transaction after it commits', () async {
    final result = await db.transaction(() async => 42);

    expect(result, 42);
    expect(recorder.events, ['COMMIT', 'SELECT 1']);
  });

  test('a nested transaction joins the outer one until it commits', () async {
    await db.transaction(() async {
      await db.transaction(() async {});
    });

    // The inner "commit" releases a savepoint; only the outer one reaches
    // storage, so only the statement after it runs outside a transaction.
    expect(recorder.events, [
      'COMMIT',
      'SELECT 1 (in tx)',
      'COMMIT',
      'SELECT 1',
    ]);
  });

  test('a rolled-back transaction issues nothing after it', () async {
    await expectLater(
      db.transaction<void>(() async => throw StateError('rollback')),
      throwsStateError,
    );

    expect(recorder.events, isEmpty);
  });
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/settings/data/loan_rules_local_data_source.dart';
import 'package:khulla/features/settings/data/mappers/loan_rules_row_mappers.dart';
import 'package:khulla/features/settings/data/tables/loan_rules.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart'
    as domain;

/// Drift-backed [LoanRulesLocalDataSource].
@LazySingleton(as: LoanRulesLocalDataSource)
class LocalLoanRulesDataSource implements LoanRulesLocalDataSource {
  LocalLoanRulesDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalLoanRulesDataSource';

  @override
  Future<domain.LoanRules?> findRules() => guardDatabase(
    () async {
      final row =
          await (_db.select(_db.loanRules)..where(
                (rules) => rules.id.equals(LoanRules.singletonId),
              ))
              .getSingleOrNull();
      return row?.toDomain();
    },
    source: '$_source.findRules',
  );

  @override
  Future<domain.LoanRules> saveRules(domain.LoanRules rules) => guardDatabase(
    () async {
      await _db.into(_db.loanRules).insertOnConflictUpdate(rules.toCompanion());
      return rules;
    },
    source: '$_source.saveRules',
  );
}

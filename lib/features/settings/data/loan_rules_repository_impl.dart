// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/settings/data/loan_rules_local_data_source.dart';
import 'package:khulla/features/settings/domain/loan_rules_repository.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart';

/// [LoanRulesRepository] over the local catalogue.
@LazySingleton(as: LoanRulesRepository)
class LoanRulesRepositoryImpl implements LoanRulesRepository {
  LoanRulesRepositoryImpl(this._dataSource);

  final LoanRulesLocalDataSource _dataSource;

  @override
  Future<LoanRules?> findRules() => _dataSource.findRules();

  @override
  Future<LoanRules> saveRules(LoanRules rules) => _dataSource.saveRules(
    rules.copyWith(updatedAt: DateTime.now()),
  );

  /// Default policy inserted on first run when no row exists yet.
  static LoanRules defaults({DateTime? updatedAt}) => LoanRules(
    loanPeriodDays: 14,
    borrowingLimit: 5,
    renewalLimit: 2,
    finePerDay: Money.major(5),
    graceDays: 1,
    maximumFinePerCopy: Money.major(500),
    membershipDurationMonths: 12,
    reservationLimit: 3,
    holdShelfDays: 7,
    blockOverdueBorrowers: true,
    autoRenewWhenUnreserved: false,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}

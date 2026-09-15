// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';

/// Read-side loan queries used by circulation lists and rule checks.
///
/// Writes still live in the circulation repository; there is no production
/// impl beyond the test stub yet.
abstract interface class LoanLocalDataSource {
  Future<LoanListResult> findLoans(LoanQuery query);

  Future<LoanListResult> findOpenLoans(LoanQuery query);

  Future<Loan?> findLoanById(String id);

  Future<Loan?> findOpenLoanByCopyId(String copyId);

  Future<Loan?> findOpenLoanByBarcode(String barcode);

  Future<int> countOpenLoansForMember(String memberId);

  Future<bool> memberHasOverdueLoans(String memberId);
}

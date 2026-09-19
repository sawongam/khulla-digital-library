// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine_query.dart';

/// Read-side fine queries and per-member outstanding totals.
abstract interface class FineLocalDataSource {
  Future<FineListResult> findFines(FineQuery query);

  Future<Fine?> findFineById(String id);

  Future<Money> outstandingForMember(String memberId);
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';

part 'copy.freezed.dart';

/// One physical item on a shelf.
@freezed
abstract class Copy with _$Copy {
  const factory Copy({
    required String id,
    required String barcode,
    required String titleId,
    required String titleName,
    required String shelf,
    required CopyStatus status,
    required DateTime acquiredAt,
    String? borrower,
    DateTime? dueAt,
    String? notes,
    DateTime? archivedAt,
  }) = _Copy;

  const Copy._();

  String get acquired => AppDateFormat.format(acquiredAt);

  String? get dueDate => dueAt == null ? null : AppDateFormat.format(dueAt!);

  bool get isOverdue {
    if (dueAt == null || status != CopyStatus.onLoan) return false;
    final today = DateTime.now();
    final due = DateTime(dueAt!.year, dueAt!.month, dueAt!.day);
    final now = DateTime(today.year, today.month, today.day);
    return now.isAfter(due);
  }
}

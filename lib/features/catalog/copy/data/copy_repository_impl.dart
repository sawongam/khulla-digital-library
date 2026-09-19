// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/data/copy_local_data_source.dart';
import 'package:khulla/features/catalog/copy/domain/copy_repository.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:uuid/uuid.dart';

/// [CopyRepository] over the local catalogue.
///
/// Assigns copy ids on insert; barcode generation when omitted is delegated to
/// [CopyLocalDataSource].
@LazySingleton(as: CopyRepository)
class CopyRepositoryImpl implements CopyRepository {
  CopyRepositoryImpl(this._dataSource);

  final CopyLocalDataSource _dataSource;
  static const Uuid _uuid = Uuid();

  @override
  Future<CopyListResult> findCopies(CopyQuery query) =>
      _dataSource.findCopies(query);

  @override
  Future<List<Copy>> findCopiesByTitleId(String titleId) =>
      _dataSource.findCopiesByTitleId(titleId);

  @override
  Future<Copy?> findCopyByBarcode(String barcode) =>
      _dataSource.findCopyByBarcode(barcode);

  @override
  Future<Copy> addCopy({
    required String titleId,
    required String titleName,
    String? shelf,
    String? barcode,
    String? notes,
  }) async {
    final now = DateTime.now();
    return await _dataSource.insertCopy(
      copy: Copy(
        id: _uuid.v4(),
        barcode: barcode ?? '',
        titleId: titleId,
        titleName: titleName,
        shelf: shelf?.trim() ?? '',
        status: CopyStatus.available,
        acquiredAt: now,
        notes: notes?.trim(),
      ),
      barcodeOverride: barcode?.trim(),
    );
  }

  @override
  Future<void> archiveCopy(String id) =>
      _dataSource.archiveCopy(id, DateTime.now());

  @override
  Future<Copy> updateCopyStatus(
    String id, {
    required CopyStatus status,
  }) async {
    final existing = await _dataSource.findCopyById(id);
    if (existing == null) {
      throw const NotFoundException('That copy was not found.');
    }
    if (existing.status == CopyStatus.onLoan) {
      throw const ConflictException(
        'That copy is on loan - return it at the desk first.',
      );
    }
    if (existing.status == CopyStatus.reserved &&
        status != CopyStatus.reserved) {
      throw const ConflictException(
        'That copy is reserved for a hold - cancel or fulfil the hold first.',
      );
    }
    return await _dataSource.updateCopy(
      existing.copyWith(status: status),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/data/isbn_lookup_remote_data_source.dart';
import 'package:khulla/features/catalog/title/domain/isbn.dart';
import 'package:khulla/features/catalog/title/domain/isbn_lookup_repository.dart';
import 'package:khulla/features/catalog/title/domain/models/isbn_lookup_result.dart';

/// [IsbnLookupRepository] that validates the ISBN before spending a request.
@LazySingleton(as: IsbnLookupRepository)
class IsbnLookupRepositoryImpl implements IsbnLookupRepository {
  IsbnLookupRepositoryImpl(this._remote);

  final IsbnLookupRemoteDataSource _remote;

  @override
  Future<IsbnLookupResult> lookUpIsbn(String isbn) async {
    final normalized = normalizeIsbn(isbn);
    if (normalized == null) {
      throw const InvalidInputException.because(AppErrorReason.isbnInvalid);
    }
    final result = await _remote.fetchByIsbn(normalized);
    if (result == null) {
      throw const NotFoundException.because(AppErrorReason.isbnNotFound);
    }
    return result;
  }
}

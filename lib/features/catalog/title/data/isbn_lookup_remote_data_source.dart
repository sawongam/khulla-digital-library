// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/title/domain/models/isbn_lookup_result.dart';

/// An online catalogue queried by a normalised ISBN.
abstract interface class IsbnLookupRemoteDataSource {
  /// Null when the catalogue has no record. Throws `NetworkException` when it
  /// cannot be reached or answers with an error.
  Future<IsbnLookupResult?> fetchByIsbn(String isbn);
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/title/domain/models/isbn_lookup_result.dart';

/// Looks a book up by ISBN in an online catalogue.
///
/// Only called when the librarian asks - nothing else in the app goes online.
abstract interface class IsbnLookupRepository {
  /// Throws `InvalidInputException` (`isbnInvalid`) for text that is not an
  /// ISBN, `NotFoundException` (`isbnNotFound`) when the catalogue has no such
  /// book, and `NetworkException` (`isbnLookupOffline`) when it cannot be
  /// reached.
  Future<IsbnLookupResult> lookUpIsbn(String isbn);
}

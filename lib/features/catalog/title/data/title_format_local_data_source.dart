// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/title/domain/models/title_format.dart';

/// Reference rows for catalogue format pickers and bootstrap seeding.
abstract interface class TitleFormatLocalDataSource {
  Future<int> countFormats();

  Future<List<TitleFormat>> findActiveFormats();

  Future<TitleFormat> insertFormat(TitleFormat format);

  Future<TitleFormat> updateFormat(TitleFormat format);

  Future<void> archiveFormat(String id, DateTime archivedAt);
}

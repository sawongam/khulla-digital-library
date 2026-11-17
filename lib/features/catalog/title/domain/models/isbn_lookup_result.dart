// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:equatable/equatable.dart';

/// What an online catalogue knows about one ISBN - the fields the title form
/// can take. Every field but [title] may be absent.
class IsbnLookupResult extends Equatable {
  const IsbnLookupResult({
    required this.title,
    this.author,
    this.publisher,
    this.publishedYear,
    this.pages,
  });

  final String title;

  /// Author names joined with ", ".
  final String? author;
  final String? publisher;
  final int? publishedYear;
  final int? pages;

  @override
  List<Object?> get props => [title, author, publisher, publishedYear, pages];
}

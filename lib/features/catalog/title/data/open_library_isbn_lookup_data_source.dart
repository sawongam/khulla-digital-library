// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/data/isbn_lookup_remote_data_source.dart';
import 'package:khulla/features/catalog/title/domain/models/isbn_lookup_result.dart';

/// [IsbnLookupRemoteDataSource] over Open Library's `api/books` endpoint.
///
/// One request returns title, authors, publishers, date and page count. The
/// service answers `{}` for an unknown ISBN, and sends CORS headers, so the
/// same call works on the web.
@LazySingleton(as: IsbnLookupRemoteDataSource)
class OpenLibraryIsbnLookupDataSource implements IsbnLookupRemoteDataSource {
  OpenLibraryIsbnLookupDataSource(this._client);

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<IsbnLookupResult?> fetchByIsbn(String isbn) async {
    final uri = Uri.https('openlibrary.org', '/api/books', {
      'bibkeys': 'ISBN:$isbn',
      'format': 'json',
      'jscmd': 'data',
    });

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on Object {
      throw const NetworkException.because(AppErrorReason.isbnLookupOffline);
    }
    if (response.statusCode != 200) {
      throw const NetworkException.because(AppErrorReason.isbnLookupOffline);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const NetworkException.because(AppErrorReason.isbnLookupOffline);
    }
    return parse(decoded, isbn);
  }

  /// Reads the record for [isbn] out of a decoded response, or null when the
  /// response holds none (or none with a title).
  static IsbnLookupResult? parse(Object? decoded, String isbn) {
    if (decoded is! Map<String, Object?>) return null;
    final record = decoded['ISBN:$isbn'];
    if (record is! Map<String, Object?>) return null;

    final title = _text(record['title']);
    if (title == null) return null;

    final authors = _names(record['authors']);
    final publishers = _names(record['publishers']);
    final pages = record['number_of_pages'];

    return IsbnLookupResult(
      title: title,
      author: authors.isEmpty ? null : authors.join(', '),
      publisher: publishers.isEmpty ? null : publishers.first,
      publishedYear: _year(record['publish_date']),
      pages: pages is int && pages > 0 ? pages : null,
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _names(Object? value) {
    if (value is! List<Object?>) return const [];
    return [
      for (final entry in value)
        if (entry is Map<String, Object?>) ?_text(entry['name']),
    ];
  }

  /// `publish_date` is free text ("October 1, 1988", "1985", "c1999").
  static int? _year(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'(?<!\d)(\d{4})(?!\d)').firstMatch(value);
    return match == null ? null : int.parse(match.group(1)!);
  }
}

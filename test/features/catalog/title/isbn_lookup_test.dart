// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/data/isbn_lookup_repository_impl.dart';
import 'package:khulla/features/catalog/title/data/open_library_isbn_lookup_data_source.dart';
import 'package:khulla/features/catalog/title/domain/isbn.dart';
import 'package:khulla/features/catalog/title/domain/models/isbn_lookup_result.dart';

IsbnLookupRepositoryImpl _repository(
  Future<http.Response> Function(http.Request) handler,
) => IsbnLookupRepositoryImpl(
  OpenLibraryIsbnLookupDataSource(MockClient(handler)),
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('normalizeIsbn', () {
    test('strips spaces and hyphens and accepts ISBN-13 and ISBN-10', () {
      expect(normalizeIsbn('978-0-14-032872-1'), '9780140328721');
      expect(normalizeIsbn(' 0 14 032872 6 '), '0140328726');
      expect(normalizeIsbn('080442957x'), '080442957X');
    });

    test('rejects wrong length, letters and bad check digits', () {
      expect(normalizeIsbn(''), isNull);
      expect(normalizeIsbn('12345'), isNull);
      expect(normalizeIsbn('978014032872a'), isNull);
      expect(normalizeIsbn('9780140328722'), isNull);
      expect(normalizeIsbn('0140328727'), isNull);
    });
  });

  group('OpenLibraryIsbnLookupDataSource.parse', () {
    test('reads title, authors, publisher, year and pages', () {
      final result = OpenLibraryIsbnLookupDataSource.parse({
        'ISBN:9780140328721': {
          'title': 'Fantastic Mr. Fox',
          'authors': [
            {'name': 'Roald Dahl'},
            {'name': 'Quentin Blake'},
          ],
          'publishers': [
            {'name': 'Puffin'},
          ],
          'publish_date': 'October 1, 1988',
          'number_of_pages': 96,
        },
      }, '9780140328721');

      expect(
        result,
        const IsbnLookupResult(
          title: 'Fantastic Mr. Fox',
          author: 'Roald Dahl, Quentin Blake',
          publisher: 'Puffin',
          publishedYear: 1988,
          pages: 96,
        ),
      );
    });

    test('leaves missing fields null and ignores non-year dates', () {
      final result = OpenLibraryIsbnLookupDataSource.parse({
        'ISBN:1': {'title': 'Bare', 'publish_date': 'n.d.'},
      }, '1');
      expect(
        result,
        const IsbnLookupResult(title: 'Bare'),
      );
    });

    test('returns null for an empty response', () {
      expect(OpenLibraryIsbnLookupDataSource.parse({}, '1'), isNull);
    });
  });

  group('IsbnLookupRepositoryImpl', () {
    test('returns the record and queries the normalised ISBN', () async {
      late Uri requested;
      final repository = _repository((request) async {
        requested = request.url;
        return _json({
          'ISBN:9780140328721': {'title': 'Fantastic Mr. Fox'},
        });
      });

      final result = await repository.lookUpIsbn('978-0-14-032872-1');

      expect(result.title, 'Fantastic Mr. Fox');
      expect(requested.host, 'openlibrary.org');
      expect(requested.queryParameters['bibkeys'], 'ISBN:9780140328721');
    });

    test('an empty object is isbnNotFound', () async {
      final repository = _repository((_) async => _json(<String, Object>{}));

      await expectLater(
        repository.lookUpIsbn('9780140328721'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.isbnNotFound,
          ),
        ),
      );
    });

    test('a network error is isbnLookupOffline', () async {
      final repository = _repository(
        (_) async => throw http.ClientException('no route'),
      );

      await expectLater(
        repository.lookUpIsbn('9780140328721'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.isbnLookupOffline,
          ),
        ),
      );
    });

    test('a server error is isbnLookupOffline', () async {
      final repository = _repository((_) async => http.Response('', 503));

      await expectLater(
        repository.lookUpIsbn('9780140328721'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('an invalid ISBN is refused without a request', () async {
      var calls = 0;
      final repository = _repository((_) async {
        calls++;
        return _json(<String, Object>{});
      });

      await expectLater(
        repository.lookUpIsbn('123'),
        throwsA(
          isA<InvalidInputException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.isbnInvalid,
          ),
        ),
      );
      expect(calls, 0);
    });
  });
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';

/// A search box's text as a `WHERE` condition over a trigram FTS5 [table].
///
/// Every whitespace-separated term must appear somewhere in [columns], in
/// any order - `potter rowling` finds the title whose author is Rowling.
/// Terms of three characters or more go through `MATCH` and the trigram
/// index. Shorter ones cannot, since a trigram index has nothing to look up
/// for them, so they fall back to `LIKE` over the same table's text.
///
/// [rowid] is the filtered row's rowid expression, e.g. `t.rowid`. Returns
/// null for a blank search, so the caller adds no condition at all.
({String sql, List<Variable<Object>> variables})? ftsFilter({
  required String search,
  required String table,
  required List<String> columns,
  required String rowid,
}) {
  final terms = search.trim().split(_whitespace)..removeWhere((t) => t.isEmpty);
  if (terms.isEmpty) return null;

  final conditions = <String>[];
  final variables = <Variable<Object>>[];

  final indexed = [
    for (final term in terms)
      if (term.runes.length >= _trigram) term,
  ];
  if (indexed.isNotEmpty) {
    conditions.add('$table MATCH ?');
    variables.add(Variable<String>(indexed.map(_phrase).join(' ')));
  }

  for (final term in terms) {
    if (term.runes.length >= _trigram) continue;
    conditions.add(
      '(${columns.map((column) => "$column LIKE ? ESCAPE '\\'").join(' OR ')})',
    );
    final pattern = '%${_escapeLike(term)}%';
    variables.addAll([for (final _ in columns) Variable<String>(pattern)]);
  }

  return (
    sql:
        '$rowid IN (SELECT rowid FROM $table WHERE ${conditions.join(' AND ')})',
    variables: variables,
  );
}

const int _trigram = 3;

final RegExp _whitespace = RegExp(r'\s+');

/// A quoted FTS5 phrase, so operators and punctuation in the term are
/// matched as text rather than parsed as query syntax.
String _phrase(String term) => '"${term.replaceAll('"', '""')}"';

String _escapeLike(String term) =>
    term.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

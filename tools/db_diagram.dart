// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

// Generates docs/database/schema.md - a Mermaid ER diagram plus per-table
// notes - from the latest drift schema snapshot. Run with `make db-diagram`.
//
// The snapshot (drift_schemas/app_database/drift_schema_v<N>.json) is written
// by `make migrate`, so the diagram always matches the schema the migration
// tests verified. Never hand-edit the generated markdown.

import 'dart:convert';
import 'dart:io';

/// Drift table name to the Dart file declaring it, for the per-table notes.
/// Tables missing here fall back to a generic pointer at AppDatabase.
const Map<String, String> _tableSources = <String, String>{
  'library_settings': 'lib/features/settings/data/tables/library_settings.dart',
  'loan_rules': 'lib/features/settings/data/tables/loan_rules.dart',
  'staff': 'lib/features/users/data/tables/staff.dart',
  'title_formats': 'lib/features/catalog/title/data/tables/title_formats.dart',
  'member_types': 'lib/features/members/data/tables/member_types.dart',
  'titles': 'lib/features/catalog/title/data/tables/titles.dart',
  'copies': 'lib/features/catalog/copy/data/tables/copies.dart',
  'members': 'lib/features/members/data/tables/members.dart',
  'loans': 'lib/features/circulation/loan/data/tables/loans.dart',
  'fines': 'lib/features/circulation/fine/data/tables/fines.dart',
  'reservations':
      'lib/features/circulation/reservation/data/tables/reservations.dart',
};

/// Drift column types to the display types used in the diagram.
const Map<String, String> _displayTypes = <String, String>{
  'int': 'INTEGER',
  'string': 'TEXT',
  'bool': 'BOOLEAN',
  'dateTime': 'DATETIME',
  'double': 'REAL',
  'blob': 'BLOB',
};

/// Matches `"col" TYPE ... REFERENCES "parent" ("parent_col")` in the
/// exported CREATE TABLE statements, the only place local FK columns appear.
final RegExp _fkPattern = RegExp(
  r'"([A-Za-z_]\w*)"\s+\w+[^,()]*?REFERENCES\s+"?([A-Za-z_]\w*)"?\s*\(\s*"([A-Za-z_]\w*)"?\s*\)',
  caseSensitive: false,
);

/// Matches the snapshot files drift writes on `make migrate`.
final RegExp _snapshotPattern = RegExp(r'drift_schema_v(\d+)\.json');

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final root = File.fromUri(Platform.script).parent.parent;
  final schemaDir = Directory('${root.path}/drift_schemas/app_database');

  final entries = schemaDir.listSync();
  final snapshots = <File>[
    for (final entry in entries)
      if (entry is File && _snapshotPattern.hasMatch(_basename(entry.path)))
        entry,
  ];
  if (snapshots.isEmpty) {
    stderr.writeln(
      'No drift_schema_v*.json in ${schemaDir.path}. Run `make migrate` first.',
    );
    exit(2);
  }

  var latest = snapshots.first;
  var latestVersion = _snapshotVersion(latest.path);
  for (final candidate in snapshots.skip(1)) {
    final version = _snapshotVersion(candidate.path);
    if (version > latestVersion) {
      latest = candidate;
      latestVersion = version;
    }
  }

  final raw = latest.readAsStringSync();
  final Object? decoded = jsonDecode(raw);
  if (decoded is! Map<String, Object?>) {
    stderr.writeln('Unexpected schema root in ${latest.path}.');
    exit(2);
  }

  final createSqlByTable = _createSqlByTable(decoded);

  final tables = <_TableSnapshot>[];
  for (final entity in _asList(decoded['entities'], 'entities')) {
    final map = _asMap(entity, 'entities[]');
    if (map['type'] == 'table') {
      tables.add(_parseTable(map));
    }
  }
  tables.sort((a, b) => a.name.compareTo(b.name));

  final relations = <_Relation>[];
  for (final table in tables) {
    relations.addAll(_relationsFor(table.name, createSqlByTable[table.name]));
  }
  relations.sort((a, b) {
    final byParent = a.parent.compareTo(b.parent);
    if (byParent != 0) {
      return byParent;
    }
    final byChild = a.child.compareTo(b.child);
    return byChild != 0 ? byChild : a.localColumn.compareTo(b.localColumn);
  });

  final markdown = _renderMarkdown(latestVersion, tables, relations);
  final outFile = File('${root.path}/docs/database/schema.md');

  if (checkOnly) {
    if (!outFile.existsSync()) {
      stderr.writeln(
        'docs/database/schema.md is missing. Run `make db-diagram`.',
      );
      exit(2);
    }
    if (outFile.readAsStringSync() != markdown) {
      stderr.writeln(
        'docs/database/schema.md is stale (schema v$latestVersion). '
        'Run `make db-diagram`.',
      );
      exit(1);
    }
    stdout.writeln(
      'docs/database/schema.md is up to date '
      '(schema v$latestVersion).',
    );
    return;
  }

  outFile.writeAsStringSync(markdown);
  stdout.writeln(
    'Wrote docs/database/schema.md '
    '(schema v$latestVersion, ${tables.length} tables).',
  );
}

String _basename(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  final cut = slash > backslash ? slash : backslash;
  return cut < 0 ? path : path.substring(cut + 1);
}

int _snapshotVersion(String path) {
  final match = _snapshotPattern.firstMatch(_basename(path));
  if (match == null) {
    throw FormatException('Not a drift schema snapshot: $path');
  }
  return int.parse(match.group(1)!);
}

Map<String, Object?> _asMap(Object? value, String context) {
  if (value is Map<String, Object?>) {
    return value;
  }
  throw FormatException('Expected a map at $context.');
}

List<Object?> _asList(Object? value, String context) {
  if (value is List<Object?>) {
    return value;
  }
  throw FormatException('Expected a list at $context.');
}

String _asString(Object? value, String context) {
  if (value is String) {
    return value;
  }
  throw FormatException('Expected a string at $context.');
}

bool _asBool(Object? value, String context) {
  if (value is bool) {
    return value;
  }
  throw FormatException('Expected a bool at $context.');
}

List<String> _asStringList(Object? value, String context) {
  if (value == null) {
    return <String>[];
  }
  return <String>[
    for (final element in _asList(value, context))
      _asString(element, '$context[]'),
  ];
}

Map<String, String> _createSqlByTable(Map<String, Object?> root) {
  final result = <String, String>{};
  final fixedSql = root['fixed_sql'];
  if (fixedSql is! List<Object?>) {
    return result;
  }
  for (final entry in fixedSql) {
    if (entry is! Map<String, Object?>) {
      continue;
    }
    final name = entry['name'];
    final sqlList = entry['sql'];
    if (name is! String || sqlList is! List<Object?>) {
      continue;
    }
    for (final dialectEntry in sqlList) {
      if (dialectEntry is Map<String, Object?> &&
          dialectEntry['dialect'] == 'sqlite') {
        final sql = dialectEntry['sql'];
        if (sql is String) {
          result[name] = sql;
        }
      }
    }
  }
  return result;
}

_TableSnapshot _parseTable(Map<String, Object?> entity) {
  final data = _asMap(entity['data'], 'table.data');
  final name = _asString(data['name'], 'table.data.name');

  final columns = <_ColumnSnapshot>[];
  for (final rawColumn in _asList(data['columns'], 'table.$name.columns')) {
    columns.add(_parseColumn(_asMap(rawColumn, 'table.$name.columns[]'), name));
  }

  return _TableSnapshot(
    name: name,
    columns: columns,
    primaryKey: _asStringList(data['explicit_pk'], 'table.$name.explicit_pk'),
    tableConstraints: _asStringList(
      data['constraints'],
      'table.$name.constraints',
    ),
  );
}

_ColumnSnapshot _parseColumn(Map<String, Object?> column, String tableName) {
  final context = 'table.$tableName.column';
  final name = _asString(column['name'], '$context.name');

  var unique = false;
  final defaultConstraints = column['defaultConstraints'];
  if (defaultConstraints is String && defaultConstraints.contains('UNIQUE')) {
    unique = true;
  }
  if (!unique) {
    final dialectConstraints = column['dialectAwareDefaultConstraints'];
    if (dialectConstraints is Map<String, Object?>) {
      for (final value in dialectConstraints.values) {
        if (value is String && value.contains('UNIQUE')) {
          unique = true;
        }
      }
    }
  }

  int? maxLength;
  final features = column['dsl_features'];
  if (features is List<Object?>) {
    for (final feature in features) {
      if (feature is String && feature == 'unique') {
        unique = true;
      } else if (feature is Map<String, Object?>) {
        final allowed = feature['allowed-lengths'];
        if (allowed is Map<String, Object?>) {
          final max = allowed['max'];
          if (max is int) {
            maxLength = max;
          }
        }
      }
    }
  }

  String? convertedType;
  final converter = column['type_converter'];
  if (converter is Map<String, Object?>) {
    final dartType = converter['dart_type_name'];
    if (dartType is String && dartType.isNotEmpty) {
      convertedType = dartType;
    }
  }

  return _ColumnSnapshot(
    name: name,
    moorType: _asString(column['moor_type'], '$context.$name.moor_type'),
    nullable: _asBool(column['nullable'], '$context.$name.nullable'),
    unique: unique,
    maxLength: maxLength,
    convertedType: convertedType,
  );
}

List<_Relation> _relationsFor(String table, String? createSql) {
  if (createSql == null || createSql.isEmpty) {
    return <_Relation>[];
  }
  return <_Relation>[
    for (final match in _fkPattern.allMatches(createSql))
      _Relation(
        parent: match.group(2)!,
        child: table,
        localColumn: match.group(1)!,
        parentColumn: match.group(3)!,
      ),
  ];
}

String _renderMarkdown(
  int version,
  List<_TableSnapshot> tables,
  List<_Relation> relations,
) {
  final fkColumns = <String>{
    for (final relation in relations)
      '${relation.child}.${relation.localColumn}',
  };
  final outgoing = <String, List<_Relation>>{};
  for (final relation in relations) {
    outgoing.putIfAbsent(relation.child, () => <_Relation>[]).add(relation);
  }

  final out = StringBuffer()
    ..writeln('# Database schema')
    ..writeln()
    ..writeln(
      '> DO NOT HAND-EDIT. Generated from '
      '`drift_schemas/app_database/drift_schema_v$version.json` '
      'by `tools/db_diagram.dart`. Regenerate with `make db-diagram`.',
    )
    ..writeln()
    ..writeln('## ER diagram - schema v$version')
    ..writeln()
    ..writeln('Renders on GitHub and in VS Code Markdown preview.')
    ..writeln()
    ..writeln('```mermaid')
    ..writeln('erDiagram');
  for (final table in tables) {
    out.writeln('  ${table.name} {');
    for (final column in table.columns) {
      out.writeln(
        '    ${_columnLine(table, column, fkColumns.contains('${table.name}.${column.name}'))}',
      );
    }
    out.writeln('  }');
  }
  for (final relation in relations) {
    out.writeln(
      '  ${relation.parent} ||--o{ ${relation.child} '
      ' : "${relation.localColumn} -> ${relation.parentColumn}"',
    );
  }
  out
    ..writeln('```')
    ..writeln()
    ..writeln('## Tables')
    ..writeln();
  for (final table in tables) {
    _renderTableNotes(out, table, outgoing[table.name] ?? <_Relation>[]);
  }
  return out.toString();
}

String _columnLine(_TableSnapshot table, _ColumnSnapshot column, bool isFk) {
  final type = _displayTypes[column.moorType] ?? column.moorType.toUpperCase();
  final isPk = table.primaryKey.contains(column.name);
  final keys = <String>[
    if (isPk) 'PK',
    if (isFk) 'FK',
    if (column.unique && !isPk) 'UK',
  ];
  final details = <String>[
    if (column.nullable) 'nullable' else 'required',
  ];
  final convertedType = column.convertedType;
  if (convertedType != null) {
    details.add(convertedType);
  }
  final maxLength = column.maxLength;
  if (maxLength != null) {
    details.add('max $maxLength');
  }
  return [
    '$type ${column.name}',
    if (keys.isNotEmpty) keys.join(','),
    '"${details.join(', ')}"',
  ].join(' ');
}

void _renderTableNotes(
  StringBuffer out,
  _TableSnapshot table,
  List<_Relation> outgoing,
) {
  out
    ..writeln('### `${table.name}`')
    ..writeln()
    ..writeln(
      '- Source: `${_tableSources[table.name] ?? 'a Drift Table class registered in lib/core/database/app_database.dart'}`',
    );
  for (final constraint in table.tableConstraints) {
    out.writeln('- Enforces `$constraint`.');
  }
  if (outgoing.isEmpty) {
    out.writeln('- No outgoing foreign keys.');
  } else {
    for (final relation in outgoing) {
      out.writeln(
        '- `${relation.localColumn}` references '
        '`${relation.parent}(${relation.parentColumn})`.',
      );
    }
  }
  out.writeln();
}

final class _TableSnapshot {
  const _TableSnapshot({
    required this.name,
    required this.columns,
    required this.primaryKey,
    required this.tableConstraints,
  });

  final String name;
  final List<_ColumnSnapshot> columns;
  final List<String> primaryKey;
  final List<String> tableConstraints;
}

final class _ColumnSnapshot {
  const _ColumnSnapshot({
    required this.name,
    required this.moorType,
    required this.nullable,
    required this.unique,
    required this.maxLength,
    required this.convertedType,
  });

  final String name;
  final String moorType;
  final bool nullable;
  final bool unique;
  final int? maxLength;
  final String? convertedType;
}

final class _Relation {
  const _Relation({
    required this.parent,
    required this.child,
    required this.localColumn,
    required this.parentColumn,
  });

  final String parent;
  final String child;
  final String localColumn;
  final String parentColumn;
}

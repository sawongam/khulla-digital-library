// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

// Seeds mock books (titles + copies) into a Khulla catalogue file.
//
// This is a scratch-data helper, not part of the app. It talks to the SQLite
// file directly with `package:sqlite3`, so it runs headlessly with:
//
//   fvm dart run script/seed_mock_books.dart --db <path-to-sqlite> \
//     --titles 20 --copies 2
//
// It deliberately imports nothing from `package:khulla`: anything under `lib/`
// pulls in Flutter through the database connection, which plain `dart run`
// cannot load. The INSERT shapes below mirror `TitleRepositoryImpl.saveTitle`
// and `LocalCopyDataSource.insertCopy` (ids, minor-unit prices,
// library barcode counter); search needs no column — the `titles_fts_*`
// triggers keep the FTS index current on every write. Required columns are
// validated with PRAGMA before any write, so a future schema change fails
// loudly instead of corrupting data. Copy barcodes always come from the library's own settings row, exactly
// as unattended check-in copies would — the script consumes the real sequence.
//
// The file must already exist with the app schema: open the app once first,
// which runs migrations and seeds reference rows. By default the script
// defaults to the dev-flavour catalogue in application support when --db is
// omitted (same path the app opens via `lib/main_dev.dart`). Pass --db to
// target another file.
//
// `fvm dart run script/seed_mock_books.dart --clear --db <same-file>`
// removes the rows this script previously inserted (tracked in a
// `<db>.mock-seed.json` sidecar, so real catalogue rows are never touched).

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

const String _manifestSuffix = '.mock-seed.json';
const String _seedNote = 'Mock seed data';
const Uuid _uuid = Uuid();

// System format codes seeded by the app on first open, in picker order.
// Names mirror `seedFormatName` in lib/shared/domain/reference_seed_labels.dart.
const List<(String, String)> _systemFormats = <(String, String)>[
  ('book', 'Book'),
  ('journal', 'Journal'),
  ('other', 'Other'),
];

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    _usage();
    exit(2);
  }
  if (options.help) {
    _usage();
    return;
  }

  if (options.clear) {
    _clearSeed(options.dbPath);
    return;
  }
  _seedBooks(options);
}

void _seedBooks(_Options options) {
  final dbFile = File(options.dbPath);
  if (!dbFile.existsSync()) {
    stderr.writeln(
      'Database file ${options.dbPath} does not exist. Open the app once '
      'first so it creates and migrates the catalogue, then point --db at it.',
    );
    exit(2);
  }

  final db = sqlite3.open(dbFile.path);
  try {
    db.execute('PRAGMA foreign_keys = ON');
    _requireSchema(db);
    final formatId = _ensureBookFormat(db);

    final books = _catalogue.take(options.titleCount).toList();
    final nowText = _dateTimeText(DateTime.now());
    final settings = _readBarcodeSettings(db);
    var barcodeSeq = settings.nextValue;

    final titleStmt = db.prepare(
      'INSERT INTO titles (id, title, author, isbn, publisher, '
      'published_year, edition, pages, format_id, language, description, '
      'shelf, lendable, replacement_cost, created_at, '
      'updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
    );
    final copyStmt = db.prepare(
      'INSERT INTO copies (id, title_id, barcode, shelf, status, '
      'acquired_at, notes, created_at, updated_at) '
      'VALUES (?,?,?,?,?,?,?,?,?)',
    );
    final settingsStmt = db.prepare(
      'UPDATE library_settings SET barcode_next_value = ?, updated_at = ? '
      'WHERE id = 1',
    );
    try {
      final seededTitleIds = <String>[];
      final seededCopyIds = <String>[];
      db.execute('BEGIN TRANSACTION');
      try {
        for (final book in books) {
          final titleId = _uuid.v4();
          titleStmt.execute(<Object?>[
            titleId,
            book.title,
            book.author,
            book.isbn,
            book.publisher,
            book.year,
            book.edition,
            book.pages,
            formatId,
            book.language,
            book.description,
            book.shelf,
            if (book.lendable) 1 else 0,
            (book.priceMajor * 100).round(),
            nowText,
            nowText,
          ]);
          seededTitleIds.add(titleId);
          for (var i = 0; i < options.copiesPerTitle; i++) {
            final copyId = _uuid.v4();
            copyStmt.execute(<Object?>[
              copyId,
              titleId,
              '${settings.prefix}$barcodeSeq',
              book.shelf,
              'available',
              nowText,
              _seedNote,
              nowText,
              nowText,
            ]);
            seededCopyIds.add(copyId);
            barcodeSeq++;
          }
          stdout.writeln('  + ${book.title}');
        }
        settingsStmt.execute(<Object?>[barcodeSeq, nowText]);
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }

      File(
        '${options.dbPath}$_manifestSuffix',
      ).writeAsStringSync(
        jsonEncode(<String, Object?>{
          'titleIds': seededTitleIds,
          'copyIds': seededCopyIds,
        }),
      );
      final firstBarcode = '${settings.prefix}${settings.nextValue}';
      final lastBarcode = '${settings.prefix}${barcodeSeq - 1}';
      stdout.writeln(
        'Seeded ${seededTitleIds.length} titles and '
        '${seededCopyIds.length} copies into ${options.dbPath} '
        '($firstBarcode..$lastBarcode).',
      );
    } finally {
      titleStmt.close();
      copyStmt.close();
      settingsStmt.close();
    }
  } on SqliteException catch (error) {
    stderr.writeln('Seeding failed: $error');
    exit(1);
  } finally {
    db.close();
  }
}

void _clearSeed(String dbPath) {
  final manifestFile = File('$dbPath$_manifestSuffix');
  if (!manifestFile.existsSync()) {
    stderr.writeln(
      'No mock-seed manifest at ${manifestFile.path}; nothing to clear. '
      'Seed first without --clear.',
    );
    exit(2);
  }
  if (!File(dbPath).existsSync()) {
    stderr.writeln('Database file $dbPath does not exist.');
    exit(2);
  }

  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  final titleIds = _stringList(manifest['titleIds']);
  final copyIds = _stringList(manifest['copyIds']);

  final db = sqlite3.open(dbPath);
  try {
    db.execute('PRAGMA foreign_keys = ON');
    final deleteCopy = db.prepare('DELETE FROM copies WHERE id = ?');
    final deleteTitle = db.prepare('DELETE FROM titles WHERE id = ?');
    try {
      db.execute('BEGIN TRANSACTION');
      try {
        for (final copyId in copyIds) {
          deleteCopy.execute(<Object?>[copyId]);
        }
        for (final titleId in titleIds) {
          deleteTitle.execute(<Object?>[titleId]);
        }
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    } finally {
      deleteCopy.close();
      deleteTitle.close();
    }
    manifestFile.deleteSync();
    stdout.writeln(
      'Removed ${titleIds.length} titles and ${copyIds.length} copies '
      'from $dbPath.',
    );
  } on SqliteException catch (error) {
    stderr.writeln(
      'Clear failed (a mock copy may be on loan — return it first): $error',
    );
    exit(1);
  } finally {
    db.close();
  }
}

/// Throws a readable error when the file is not a migrated Khulla catalogue.
void _requireSchema(Database db) {
  const required = <String, List<String>>{
    'titles': <String>[
      'id',
      'title',
      'author',
      'isbn',
      'publisher',
      'published_year',
      'edition',
      'pages',
      'format_id',
      'language',
      'description',
      'shelf',
      'lendable',
      'replacement_cost',
      'created_at',
      'updated_at',
    ],
    'copies': <String>[
      'id',
      'title_id',
      'barcode',
      'shelf',
      'status',
      'acquired_at',
      'notes',
      'created_at',
      'updated_at',
    ],
    'title_formats': <String>[
      'id',
      'code',
      'name',
      'sort_order',
      'is_system',
      'archived_at',
      'created_at',
    ],
    'library_settings': <String>[
      'id',
      'barcode_prefix',
      'barcode_next_value',
      'updated_at',
    ],
  };
  for (final table in required.keys) {
    final info = db.select('PRAGMA table_info($table)');
    if (info.isEmpty) {
      stderr.writeln(
        'Table "$table" is missing. This is not a migrated Khulla '
        'catalogue — open the app once first.',
      );
      exit(2);
    }
    final columns = <String>{
      for (final row in info) row['name'] as String,
    };
    for (final column in required[table]!) {
      if (!columns.contains(column)) {
        stderr.writeln(
          'Column "$table.$column" is missing. The app schema moved on — '
          'update script/seed_mock_books.dart to match.',
        );
        exit(2);
      }
    }
  }
}

/// Id of the `book` format, seeding system formats when the app never ran.
String _ensureBookFormat(Database db) {
  final existing = db.select(
    'SELECT id, code FROM title_formats WHERE archived_at IS NULL '
    'ORDER BY sort_order',
  );
  for (final row in existing) {
    final code = row['code'] as String?;
    if (code == 'book') {
      return row['id'] as String;
    }
  }
  if (existing.isNotEmpty) {
    return existing.first['id'] as String;
  }

  final nowText = _dateTimeText(DateTime.now());
  final stmt = db.prepare(
    'INSERT INTO title_formats (id, code, name, sort_order, is_system, '
    'created_at) VALUES (?,?,?,?,?,?)',
  );
  try {
    var bookId = '';
    for (var i = 0; i < _systemFormats.length; i++) {
      final id = _uuid.v4();
      if (_systemFormats[i].$1 == 'book') {
        bookId = id;
      }
      stmt.execute(<Object?>[
        id,
        _systemFormats[i].$1,
        _systemFormats[i].$2,
        i,
        1,
        nowText,
      ]);
    }
    return bookId;
  } finally {
    stmt.close();
  }
}

/// The library's own barcode counter, mirroring `LocalCopyDataSource`.
///
/// The app hands the next value out to copies added without an explicit
/// barcode and bumps the row; the script does the same, so seeded barcodes
/// continue the real `KH-1` sequence instead of living in a side series.
({String prefix, int nextValue}) _readBarcodeSettings(Database db) {
  final rows = db.select(
    'SELECT barcode_prefix, barcode_next_value FROM library_settings '
    'WHERE id = 1',
  );
  if (rows.isEmpty) {
    stderr.writeln(
      'The library_settings row is missing. Open the app once first so it '
      'seeds library defaults, then re-run.',
    );
    exit(2);
  }
  return (
    prefix: rows.single['barcode_prefix'] as String,
    nextValue: rows.single['barcode_next_value'] as int,
  );
}

/// Same text shape drift writes for `DateTime` columns.
///
/// The app sets `store_date_time_values_as_text` in build.yaml, so dates are
/// ISO-8601 text with an explicit offset (`2026-01-02T03:04:05.000 +05:45`),
/// never unix seconds. Writing anything else makes app reads throw.
String _dateTimeText(DateTime value) {
  if (value.isUtc) {
    return value.toIso8601String();
  }
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? ' -' : ' +';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() - 60 * offset.inHours.abs())
      .toString()
      .padLeft(2, '0');
  return '${value.toIso8601String()}$sign$hours:$minutes';
}

List<String> _stringList(Object? value) {
  if (value is! List<Object?>) {
    return <String>[];
  }
  return <String>[
    for (final item in value)
      if (item is String) item,
  ];
}

String _defaultDevDbPath() {
  const appId = 'com.khulladigitallibrary.app';
  const dbFile = 'khulla_dev.sqlite';

  if (Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      stderr.writeln('HOME is not set; pass --db explicitly.');
      exit(2);
    }
    return p.join(home, '.local', 'share', appId, dbFile);
  }
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) {
      stderr.writeln('LOCALAPPDATA is not set; pass --db explicitly.');
      exit(2);
    }
    return p.join(localAppData, appId, dbFile);
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      stderr.writeln('HOME is not set; pass --db explicitly.');
      exit(2);
    }
    return p.join(home, 'Library', 'Application Support', appId, dbFile);
  }

  stderr.writeln(
    'No default catalogue path on ${Platform.operatingSystem}; pass --db.',
  );
  exit(2);
}

_Options? _parseArgs(List<String> args) {
  var dbPath = _defaultDevDbPath();
  var titleCount = 20;
  var copiesPerTitle = 2;
  var clear = false;
  var help = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg == '--clear') {
      clear = true;
    } else if (arg == '--db' && i + 1 < args.length) {
      i++;
      dbPath = args[i];
    } else if (arg == '--titles' && i + 1 < args.length) {
      i++;
      titleCount = int.tryParse(args[i]) ?? -1;
    } else if (arg == '--copies' && i + 1 < args.length) {
      i++;
      copiesPerTitle = int.tryParse(args[i]) ?? -1;
    } else {
      stderr.writeln('Unknown argument: $arg');
      return null;
    }
  }

  if (!clear && (titleCount < 1 || titleCount > _catalogue.length)) {
    stderr.writeln('--titles must be between 1 and ${_catalogue.length}.');
    return null;
  }
  if (!clear && (copiesPerTitle < 1 || copiesPerTitle > 20)) {
    stderr.writeln('--copies must be between 1 and 20.');
    return null;
  }
  return _Options(
    dbPath: dbPath,
    titleCount: titleCount,
    copiesPerTitle: copiesPerTitle,
    clear: clear,
    help: help,
  );
}

void _usage() {
  final buffer = StringBuffer()
    ..writeln('Usage: fvm dart run script/seed_mock_books.dart [options]')
    ..writeln()
    ..writeln('Inserts mock books into a Khulla catalogue file.')
    ..writeln()
    ..writeln('Options:')
    ..writeln('  --db <path>             SQLite file to seed.')
    ..writeln('                          Default: dev catalogue in application')
    ..writeln('                          support (see examples below).')
    ..writeln(
      '  --titles <n>            How many of the 20 mock titles to insert',
    )
    ..writeln('                          (default 20).')
    ..writeln('  --copies <n>            Copies per title (default 2, max 20).')
    ..writeln('  --clear                 Remove previously seeded mock rows;')
    ..writeln('                          needs the same --db. Does not rewind')
    ..writeln('                          the library barcode counter.')
    ..writeln('  --help, -h              Show this help.')
    ..writeln()
    ..writeln(
      'Barcodes come from the library settings row (prefix + counter),',
    )
    ..writeln('exactly as app-added copies would get them.')
    ..writeln()
    ..writeln(
      'The file must be a catalogue the app opened at least once. Default',
    )
    ..writeln('paths (override with --db when needed):')
    ..writeln(
      '  Linux:   ~/.local/share/com.khulladigitallibrary.app/khulla_dev.sqlite',
    )
    ..writeln(
      '  Windows: %LOCALAPPDATA%/com.khulladigitallibrary.app/khulla_dev.sqlite',
    )
    ..writeln(
      '  macOS:   ~/Library/Application Support/com.khulladigitallibrary.app/khulla_dev.sqlite',
    );
  stdout.write(buffer.toString());
}

final class _Options {
  const _Options({
    required this.dbPath,
    required this.titleCount,
    required this.copiesPerTitle,
    required this.clear,
    required this.help,
  });

  final String dbPath;
  final int titleCount;
  final int copiesPerTitle;
  final bool clear;
  final bool help;
}

final class _MockBook {
  const _MockBook({
    required this.title,
    required this.author,
    required this.shelf,
    required this.priceMajor,
    this.isbn,
    this.publisher,
    this.year,
    this.edition,
    this.pages,
    this.language = 'English',
    this.description,
    this.lendable = true,
  });

  final String title;
  final String author;
  final String shelf;
  final double priceMajor;
  final String? isbn;
  final String? publisher;
  final int? year;
  final String? edition;
  final int? pages;
  final String language;
  final String? description;
  final bool lendable;
}

const List<_MockBook> _catalogue = <_MockBook>[
  _MockBook(
    title: 'Muna Madan',
    author: 'Laxmi Prasad Devkota',
    shelf: 'NEP-LIT-A1',
    priceMajor: 250,
    isbn: '978-9937-1-0001-1',
    publisher: 'Sajha Prakashan',
    year: 1936,
    pages: 120,
    language: 'Nepali',
    description: 'Verse tragedy of a merchant who leaves for Lhasa.',
  ),
  _MockBook(
    title: 'Seto Dharti',
    author: 'Amar Neupane',
    shelf: 'NEP-LIT-A1',
    priceMajor: 450,
    isbn: '978-9937-1-0002-8',
    publisher: 'FinePrint',
    year: 2012,
    pages: 360,
    language: 'Nepali',
    description: 'Madan Puraskar winner set in far-western Nepal.',
  ),
  _MockBook(
    title: 'Palpasa Café',
    author: 'Narayan Wagle',
    shelf: 'NEP-LIT-A2',
    priceMajor: 350,
    publisher: 'Nepalaya',
    year: 2005,
    pages: 240,
    description: 'A painter returns to Kathmandu during the conflict.',
  ),
  _MockBook(
    title: 'Karnali Blues',
    author: 'Buddhisagar',
    shelf: 'NEP-LIT-A2',
    priceMajor: 425,
    publisher: 'FinePrint',
    year: 2010,
    pages: 400,
    language: 'Nepali',
    description: 'A son remembers his father in the Karnali region.',
  ),
  _MockBook(
    title: 'Shirishko Phool',
    author: 'Parijat',
    shelf: 'NEP-LIT-A3',
    priceMajor: 200,
    publisher: 'Sajha Prakashan',
    year: 1964,
    pages: 120,
    language: 'Nepali',
    description: 'Madan Puraskar-winning novel of love and loss.',
  ),
  _MockBook(
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    shelf: 'FIC-B1',
    priceMajor: 550,
    isbn: '978-0-06-112008-4',
    publisher: 'J.B. Lippincott',
    year: 1960,
    pages: 281,
    description: 'Atticus Finch defends an innocent man in Alabama.',
  ),
  _MockBook(
    title: '1984',
    author: 'George Orwell',
    shelf: 'FIC-B1',
    priceMajor: 400,
    isbn: '978-0-452-28423-4',
    publisher: 'Secker & Warburg',
    year: 1949,
    edition: 'Reprint',
    pages: 328,
    description: 'Winston Smith rewrites history for the Party.',
  ),
  _MockBook(
    title: 'The Little Prince',
    author: 'Antoine de Saint-Exupéry',
    shelf: 'FIC-B2',
    priceMajor: 300,
    publisher: 'Reynal & Hitchcock',
    year: 1943,
    pages: 96,
    description: 'A pilot meets a prince from a distant asteroid.',
  ),
  _MockBook(
    title: "Harry Potter and the Philosopher's Stone",
    author: 'J.K. Rowling',
    shelf: 'CHILD-C1',
    priceMajor: 750,
    isbn: '978-0-7475-3269-9',
    publisher: 'Bloomsbury',
    year: 1997,
    pages: 223,
    description: 'Harry discovers he is a wizard and goes to Hogwarts.',
  ),
  _MockBook(
    title: 'The Alchemist',
    author: 'Paulo Coelho',
    shelf: 'FIC-B2',
    priceMajor: 450,
    publisher: 'HarperTorch',
    year: 1988,
    pages: 208,
    description: 'Santiago follows his dream to the pyramids.',
  ),
  _MockBook(
    title: 'Flutter in Action',
    author: 'Eric Windmill',
    shelf: 'TECH-D1',
    priceMajor: 3200,
    isbn: '978-1-61729-614-7',
    publisher: 'Manning',
    year: 2020,
    pages: 368,
    description: 'Hands-on guide to building apps with Flutter.',
  ),
  _MockBook(
    title: 'Dart Apprentice',
    author: 'Jonathan Sande',
    shelf: 'TECH-D1',
    priceMajor: 2800,
    publisher: 'Kodeco',
    year: 2023,
    edition: 'Second edition',
    pages: 350,
    description: 'Learn the Dart language from first principles.',
  ),
  _MockBook(
    title: 'Clean Code',
    author: 'Robert C. Martin',
    shelf: 'TECH-D2',
    priceMajor: 3600,
    isbn: '978-0-13-235088-4',
    publisher: 'Prentice Hall',
    year: 2008,
    pages: 464,
    description: 'A handbook of agile software craftsmanship.',
  ),
  _MockBook(
    title: 'Designing Data-Intensive Applications',
    author: 'Martin Kleppmann',
    shelf: 'TECH-D2',
    priceMajor: 4500,
    isbn: '978-1-4493-7332-0',
    publisher: "O'Reilly",
    year: 2017,
    pages: 616,
    description: 'Foundations of storage, replication and streaming.',
    lendable: false,
  ),
  _MockBook(
    title: 'The Gruffalo',
    author: 'Julia Donaldson',
    shelf: 'CHILD-C1',
    priceMajor: 500,
    publisher: 'Macmillan',
    year: 1999,
    pages: 32,
    description: 'A mouse outwits the monster of the deep dark wood.',
  ),
  _MockBook(
    title: "Charlotte's Web",
    author: 'E.B. White',
    shelf: 'CHILD-C2',
    priceMajor: 480,
    publisher: 'Harper & Brothers',
    year: 1952,
    pages: 192,
    description: 'A spider saves Wilbur the pig with woven words.',
  ),
  _MockBook(
    title: 'A Brief History of Time',
    author: 'Stephen Hawking',
    shelf: 'SCI-E1',
    priceMajor: 650,
    isbn: '978-0-553-38016-3',
    publisher: 'Bantam',
    year: 1988,
    edition: 'Updated edition',
    pages: 212,
    description: 'From the Big Bang to black holes.',
  ),
  _MockBook(
    title: 'Sapiens',
    author: 'Yuval Noah Harari',
    shelf: 'SCI-E1',
    priceMajor: 850,
    publisher: 'Harvill Secker',
    year: 2011,
    pages: 443,
    description: 'A brief history of humankind.',
  ),
  _MockBook(
    title: 'Gitanjali',
    author: 'Rabindranath Tagore',
    shelf: 'POE-F1',
    priceMajor: 320,
    publisher: 'Macmillan',
    year: 1910,
    pages: 104,
    description: 'Song offerings; Nobel Prize in Literature 1913.',
  ),
  _MockBook(
    title: 'Pagal Basti',
    author: 'Saru Bhakta',
    shelf: 'NEP-LIT-A3',
    priceMajor: 300,
    publisher: 'Sajha Prakashan',
    year: 1991,
    pages: 280,
    language: 'Nepali',
    description: 'Madan Puraskar-winning portrait of a hill village.',
  ),
];

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dependency rules the analyzer cannot see, checked over the source tree.
///
/// Each is a rule CLAUDE.md states and a refactor once had to restore, so it
/// is enforced here rather than trusted: a violation fails the build with
/// the file and the import that broke it.
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !_generated.hasMatch(file.path))
      .toList();

  Iterable<(String, String)> importsOf(bool Function(String path) where) => [
    for (final file in sources.where((file) => where(file.path)))
      for (final match in _import.allMatches(file.readAsStringSync()))
        (file.path, match.group(1)!),
  ];

  test('a cubit never depends on another cubit', () {
    // Bloc's own architecture guidance: blocs in the same layer must not
    // know about each other. A cubit that needs who is signed in asks
    // SessionRepository; it never reads AuthCubit.
    final violations = [
      for (final (path, uri) in importsOf(
        (path) => path.endsWith('_cubit.dart'),
      ))
        if (uri.endsWith('_cubit.dart')) '$path imports $uri',
    ];

    expect(violations, isEmpty);
  });

  test('domain never imports data, presentation or drift', () {
    final violations = [
      for (final (path, uri) in importsOf((path) => path.contains('/domain/')))
        if (uri.contains('/data/') ||
            uri.contains('/presentation/') ||
            uri.startsWith('package:drift/') ||
            uri.startsWith('package:flutter/'))
          '$path imports $uri',
    ];

    expect(violations, isEmpty);
  });

  test('no folder repeats the name of its parent feature', () {
    final violations = [
      for (final feature in Directory(
        'lib/features',
      ).listSync().whereType<Directory>())
        if (Directory(
          '${feature.path}/${feature.uri.pathSegments.where((s) => s.isNotEmpty).last}',
        ).existsSync())
          feature.path,
    ];

    expect(violations, isEmpty);
  });
}

final RegExp _import = RegExp("^import '([^']+)'", multiLine: true);
final RegExp _generated = RegExp(r'\.(g|freezed|config)\.dart$|/gen/');

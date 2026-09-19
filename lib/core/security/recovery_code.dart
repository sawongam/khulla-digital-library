// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// One-time codes for resetting the first administrator's password.
///
/// High-entropy random strings, not memorable passwords. They are hashed with
/// SHA-256 rather than bcrypt because guessing one is not practical, and
/// hashing eight of them with bcrypt would stall first-run setup.
abstract final class RecoveryCode {
  /// Crockford base32 without I, L, O or U, so a handwritten code is less
  /// likely to be misread.
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  static const int groupCount = 4;
  static const int groupLength = 4;
  static const int setSize = 8;

  static const int _bodyLength = groupCount * groupLength;

  /// [setSize] distinct formatted codes, e.g. `7K2M-9QWP-4XNH-B6RT`.
  static List<String> generateSet([Random? random]) {
    final rng = random ?? Random.secure();
    final codes = <String>{};
    while (codes.length < setSize) {
      codes.add(_format(_randomBody(rng)));
    }
    return codes.toList();
  }

  /// Strips separators and maps look-alike letters onto digits.
  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toUpperCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(switch (char) {
        'O' => '0',
        'I' || 'L' => '1',
        'U' => 'V',
        _ => char,
      });
    }
    return buffer.toString().replaceAll(RegExp('[^0-9A-Z]'), '');
  }

  /// SHA-256 hex digest of the normalized code.
  static String hash(String code) =>
      sha256.convert(utf8.encode(normalize(code))).toString();

  static bool matches(String code, String digest) => hash(code) == digest;

  /// Plain-text kit written to the downloadable file. Keep it ASCII.
  static String fileContents({
    required String libraryName,
    required List<String> codes,
  }) {
    final body = codes.map((code) => '- $code').join('\n');
    return '''
Khulla Digital Library recovery codes

Library: $libraryName

Each code can be used once to set a new administrator password if you forget yours.
Keep this file offline. Anyone who has an unused code can reset that password.

$body
''';
  }

  static String _randomBody(Random rng) {
    final buffer = StringBuffer();
    for (var i = 0; i < _bodyLength; i++) {
      buffer.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  static String _format(String body) {
    final groups = <String>[];
    for (var i = 0; i < groupCount; i++) {
      final start = i * groupLength;
      groups.add(body.substring(start, start + groupLength));
    }
    return groups.join('-');
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';

/// Hashes and verifies staff passwords.
///
/// bcrypt, because the alternative in a local-first app is worse than it
/// looks: there is no server to rate-limit against, so whoever holds the
/// database file can try passwords as fast as the hash lets them. A salted,
/// deliberately slow hash is what turns "every password by lunchtime" into
/// "one password, maybe". A raw SHA of the password would be neither salted
/// nor slow.
///
/// Pure Dart, so the same code runs on Windows, the web build and everything
/// between — no FFI, no per-platform crypto backend to keep in step.
///
/// [hash] and [verify] are synchronous and deliberately expensive — a
/// noticeable fraction of a second each. Call them from a cubit that is
/// already showing a submitting state, never inside `build`.
@lazySingleton
class PasswordHasher {
  /// bcrypt accepts at most this many UTF-8 bytes — longer input throws an
  /// [ArgumentError] inside the package, past every guard.
  static const int maxPasswordBytes = 72;

  /// A salted bcrypt digest of [password], safe to store as-is.
  ///
  /// The salt is generated per call and travels inside the returned string,
  /// so there is no second column to add and no salt to manage. It carries
  /// the package's default work factor of 2^10; raising it later invalidates
  /// nothing, because the cost is recorded inside each hash and existing
  /// accounts keep verifying at the factor they were created with.
  /// Throws [InvalidInputException] when [password] exceeds
  /// [maxPasswordBytes], so callers that only handle [AppException] still
  /// render it instead of sticking in a submitting state. The form validator
  /// rejects this first; this is the backstop for any path that skips it.
  String hash(String password) {
    if (utf8.encode(password).length > maxPasswordBytes) {
      throw const InvalidInputException('That password is too long.');
    }
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Whether [password] produced [hash].
  ///
  /// Returns false rather than throwing on a malformed [hash] — a corrupted
  /// or hand-edited row must read as "wrong password", not as a crash on the
  /// sign-in screen.
  bool verify(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } on Object {
      return false;
    }
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which staff account is signed in on this device.
///
/// A stored id, not a token: there is no server to issue one and nothing to
/// revoke. Whoever can read this key can already read the catalogue file next
/// to it, so the id buys convenience - the desk machine does not ask for a
/// password every morning - and claims no more security than that.
///
/// The id is checked against the staff table on every restore, so an account
/// that was deleted or disabled since the last session does not come back.
@lazySingleton
class AuthSessionStorage {
  AuthSessionStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _staffIdKey = 'khulla.session.staff_id';

  /// The signed-in account's id, or null when nobody is signed in here.
  String? readStaffId() => _prefs.getString(_staffIdKey);

  Future<void> saveStaffId(String id) => _prefs.setString(_staffIdKey, id);

  Future<void> clearStaffId() => _prefs.remove(_staffIdKey);
}

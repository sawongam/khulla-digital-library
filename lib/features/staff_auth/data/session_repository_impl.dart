// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/storage/storage_persistence.dart' as persistence;
import 'package:khulla/features/staff_auth/data/auth_session_storage.dart';
import 'package:khulla/features/staff_auth/domain/models/session.dart';
import 'package:khulla/features/staff_auth/domain/session_repository.dart';
import 'package:khulla/features/users/data/staff_local_data_source.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';

/// [SessionRepository] held in memory, with the signed-in account's id
/// remembered in [AuthSessionStorage] across starts.
///
/// Reads the staff table through [StaffLocalDataSource] rather than
/// `StaffRepository`, because `StaffRepository` asks this class who is
/// acting - depending on it back would be a cycle.
@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._staff, this._storage);

  final StaffLocalDataSource _staff;
  final AuthSessionStorage _storage;

  /// Never closed: like `AuthCubit`, the one listener, this lives as long
  /// as the app does.
  final StreamController<Session> _changes =
      StreamController<Session>.broadcast();

  Session _current = Session.unknown;

  @override
  Session get current => _current;

  @override
  Stream<Session> get changes => _changes.stream;

  @override
  Future<Session> restoreSession() async {
    if (!await _staff.hasAnyStaff()) {
      return _set(const Session(status: AuthStatus.needsSetup));
    }

    final staffId = _storage.readStaffId();
    final staff = staffId == null ? null : await _staff.findStaffById(staffId);

    // A remembered account that has since been deleted or disabled is not a
    // session. Drop the stored id so the next start does not retry it.
    if (staff == null || !staff.canSignIn) {
      if (staffId != null) await _storage.clearStaffId();
      return _set(const Session(status: AuthStatus.signedOut));
    }

    return _set(Session(status: AuthStatus.signedIn, staff: staff));
  }

  @override
  Future<void> startSession(StaffMember staff) async {
    _set(Session(status: AuthStatus.signedIn, staff: staff));
    await _storage.saveStaffId(staff.id);
    // A sign-in is the moment a person has just acted on the page, which is
    // when browsers are most willing to promise to keep its storage. On the
    // web this keeps the catalogue from being treated as best-effort data
    // the browser may clear; on native it is a no-op. It never throws, and
    // nothing waits on it - the Backup page reports the outcome.
    unawaited(persistence.requestPersistentStorage());
  }

  @override
  void refreshSignedInStaff(StaffMember staff) {
    if (_current.isSignedIn && _current.staff?.id == staff.id) {
      _set(_current.copyWith(staff: staff));
    }
  }

  @override
  Future<void> endSession() async {
    _set(const Session(status: AuthStatus.signedOut));
    await _storage.clearStaffId();
  }

  @override
  StaffMember requireSignedInStaff() {
    final staff = _current.staff;
    if (!_current.isSignedIn || staff == null) {
      throw const SignedOutException();
    }
    return staff;
  }

  Session _set(Session session) {
    _current = session;
    _changes.add(session);
    return session;
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/staff_auth/domain/models/session.dart';
import 'package:khulla/features/staff_auth/domain/session_repository.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_state.dart';

/// The app-wide session, as the widget tree and the router see it.
///
/// A mirror of [SessionRepository], which owns who is signed in: this cubit
/// follows its [SessionRepository.changes] so the router's
/// `refreshListenable` and every `context.watch<AuthCubit>()` rebuild when
/// somebody signs in or out. Other cubits never read it - a cubit that needs
/// the signed-in account asks the repository that needs it, and repositories
/// ask [SessionRepository].
///
/// It is a [lazySingleton] and therefore never closed - no `isClosed`
/// guards here, deliberately. [close] still cancels the subscription, for
/// tests that build one directly.
@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._session) : super(_stateFor(_session.current)) {
    _subscription = _session.changes.listen(
      (session) => emit(_stateFor(session)),
    );
  }

  final SessionRepository _session;
  late final StreamSubscription<Session> _subscription;

  /// Resolves the starting status: set up or not, signed in or not.
  ///
  /// Called from `bootstrap` before the first frame so the router's first
  /// redirect already knows the answer. A failure to read leaves the status
  /// [AuthStatus.unknown] with the error in state - the catalogue is not
  /// answering, and guessing "needs setup" would offer to create a second
  /// administrator over the top of a real library.
  Future<void> restoreSession() async {
    try {
      emit(_stateFor(await _session.restoreSession()));
    } on AppException catch (error) {
      emit(AuthState(error: error));
    }
  }

  /// Ends the session on this device.
  Future<void> signOut() => _session.endSession();

  static AuthState _stateFor(Session session) =>
      AuthState(status: session.status, staff: session.staff);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}

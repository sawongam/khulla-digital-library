// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/config/flavor.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/features/circulation/check_out/presentation/cubit/check_out_cubit.dart';
import 'package:khulla/features/circulation/loan/presentation/cubit/loan_list_cubit.dart';
import 'package:khulla/features/circulation/return_copy/presentation/cubit/return_cubit.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/members/presentation/cubit/member_detail_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_cubit.dart';
import 'package:khulla/features/staff_auth/domain/session_repository.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/recover_password/cubit/recover_password_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The generated dependency graph compiles and resolves.
///
/// `injection.config.dart` is excluded from analysis like every generated
/// file, and nothing else under `test/` imports it - so a binding that does
/// not type-check (a dispose hook on an interface, a constructor argument
/// nobody registers) would otherwise surface only when the app is built.
/// Resolving constructs objects without running a query: drift connects on
/// the first one, and none runs here.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies(
      const AppConfig(
        flavor: Flavor.dev,
        databaseName: 'khulla_di_test',
        windowTitle: 'test',
      ),
    );
    // The real database binding reaches for path_provider, which has no
    // platform side in a VM test. Swap in an in-memory one before anything
    // resolves; every binding that takes `AppDatabase` is still the real one.
    getIt
      ..allowReassignment = true
      ..registerSingleton<AppDatabase>(
        AppDatabase.connect(NativeDatabase.memory()),
      );
  });

  tearDownAll(getIt.reset);

  test('the session is one instance, shared by everything that asks', () {
    expect(
      identical(getIt<SessionRepository>(), getIt<SessionRepository>()),
      isTrue,
    );
    expect(getIt<AuthCubit>().state.isResolved, isFalse);
  });

  test('every cubit and repository touched by the session resolves', () {
    expect(getIt<StaffRepository>(), isNotNull);
    expect(getIt<CirculationRepository>(), isNotNull);
    expect(getIt<SignInCubit>(), isNotNull);
    expect(getIt<RecoverPasswordCubit>(), isNotNull);
    expect(getIt<OnboardingCubit>(), isNotNull);
    expect(getIt<CheckOutCubit>(), isNotNull);
    expect(getIt<ReturnCubit>(), isNotNull);
    expect(getIt<LoanListCubit>(), isNotNull);
    expect(getIt<MemberDetailCubit>(), isNotNull);
    expect(getIt<StaffListCubit>(), isNotNull);
    expect(getIt<StaffFormCubit>(), isNotNull);
    expect(getIt<BackupCubit>(), isNotNull);
    expect(getIt<LibraryProfileCubit>(), isNotNull);
  });
}

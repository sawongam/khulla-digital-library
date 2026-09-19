// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/theme/cubit/theme_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/shared/presentation/cubit/library_branding_cubit.dart';
import 'package:khulla/shared/presentation/cubit/reference_data_cubit.dart';

/// Root [BlocProvider]s for the widget tree.
///
/// App-wide cubits are resolved from the service locator here and nowhere
/// else — a widget deeper in the tree reads them with `context.read`, never
/// with `getIt`, so it stays testable by wrapping it in a provider.
class AppBlocProviders extends StatelessWidget {
  const AppBlocProviders({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final referenceData = getIt<ReferenceDataCubit>();
    unawaited(referenceData.loadReferenceData());
    final branding = getIt<LibraryBrandingCubit>();
    unawaited(branding.loadLogo());

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
        BlocProvider<ReferenceDataCubit>.value(value: referenceData),
        BlocProvider<LibraryBrandingCubit>.value(value: branding),
      ],
      child: child,
    );
  }
}

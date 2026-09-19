// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/app/app_bloc_providers.dart';
import 'package:khulla/app/router/app_router.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/feedback/app_toast_wrapper.dart';
import 'package:khulla/core/theme/app_language.dart';
import 'package:khulla/core/theme/cubit/theme_cubit.dart';
import 'package:khulla/core/theme/cubit/theme_state.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/widgets/dismiss_keyboard.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Root widget: providers, theming, localization, and the router.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => AppBlocProviders(
    child: AppToastWrapper(
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, appearance) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appName,
          theme: AppTheme.light(AppDensity.comfortable, appearance.brand),
          darkTheme: AppTheme.dark(AppDensity.comfortable, appearance.brand),
          themeMode: appearance.mode,
          // Lets a mouse drag a list, which Flutter disallows by default.
          scrollBehavior: const AppScrollBehavior(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: appearance.language.locale,
          routerConfig: getIt<AppRouter>().router,
          // AppResponsiveTheme re-resolves the theme for the window's size
          // class and caps text scaling.
          builder: (context, child) => DismissKeyboard(
            child: AppResponsiveTheme(
              brand: appearance.brand,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
}

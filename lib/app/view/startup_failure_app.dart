// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/app/app.dart' show App;
import 'package:khulla/app/view/app.dart' show App;
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Shown instead of [App] when the database could not be opened.
///
/// A library's catalogue is its only copy of its records, so the failure modes
/// here are ones an operator has to act on - a file locked by another copy of
/// the app, a disk that is full, a database written by a newer build. A red
/// screen or a silent crash tells them none of that; this does, in their own
/// language, with a retry for the transient cases.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    required this.error,
    required this.onRetry,
    super.key,
  });

  /// What went wrong while opening the database.
  final AppException error;

  /// Re-runs the failed startup step.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => context.l10n.appName,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppPageBody(
        child: Center(
          child: SingleChildScrollView(
            child: ErrorRetryView(error: error, onRetry: onRetry),
          ),
        ),
      ),
    ),
  );
}

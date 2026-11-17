// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:http/http.dart' as http;
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/lifecycle/restart_app.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_download.dart';

UpdateChannel detectUpdateChannel() => UpdateChannel.web;

/// The web build never downloads an installer - the server already has the
/// new version.
Future<String> downloadInstaller(
  http.Client client,
  UpdateDownload download, {
  required void Function(double progress) onProgress,
  String? directory,
}) => throw UnsupportedError('The web build has no installer to download.');

/// Reloads the page, which loads whatever build the server now has. The
/// catalogue in browser storage is untouched; the new build migrates it on
/// open, exactly as a native one does.
Future<void> handOverToUpdate(
  AppDatabase db,
  AppConfig config, {
  required String? installerPath,
  required String runningVersion,
}) async => restartApp();

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:khulla/core/config/app_info.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/updates/data/update_manifest_remote_data_source.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_download.dart';
import 'package:khulla/features/updates/domain/models/update_release.dart';

/// [UpdateManifestRemoteDataSource] over plain HTTPS.
///
/// Native installs read `latest.json`, which `release.yaml` attaches to every
/// GitHub release. The web build reads the `version.json` that `flutter
/// build web` writes beside `index.html` - the server it was loaded from is
/// the one that knows whether a newer build has been deployed, and GitHub
/// does not send the CORS headers a browser would need anyway.
///
/// **`latest.json` is a contract with every install ever shipped.** Old
/// builds keep reading it for as long as they run. `version`, `build` and
/// `notes` must never change meaning; anything new is an added field, and
/// a reader ignores the fields it does not know.
@LazySingleton(as: UpdateManifestRemoteDataSource)
class HttpUpdateManifestDataSource implements UpdateManifestRemoteDataSource {
  HttpUpdateManifestDataSource(this._client);

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<UpdateRelease> fetchLatestRelease(UpdateChannel channel) async {
    if (channel == UpdateChannel.web) {
      // A query nobody reads, so neither the browser nor a CDN can answer
      // from a copy cached before the deploy.
      final uri = Uri.base
          .resolve('version.json')
          .replace(
            queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
          );
      return parseWebVersion(await _fetchJson(uri));
    }
    return parseManifest(
      await _fetchJson(Uri.parse(AppInfo.latestReleaseManifestUrl)),
      channel,
    );
  }

  Future<Object?> _fetchJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on Object {
      throw const NetworkException.because(AppErrorReason.updateCheckFailed);
    }
    if (response.statusCode != 200) {
      throw const NetworkException.because(AppErrorReason.updateCheckFailed);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      // A captive portal's sign-in page, most likely.
      throw const NetworkException.because(AppErrorReason.updateCheckFailed);
    }
  }

  /// Reads a release out of a decoded `latest.json`, with the download
  /// [channel] would run.
  @visibleForTesting
  static UpdateRelease parseManifest(Object? decoded, UpdateChannel channel) {
    if (decoded is! Map<String, Object?>) throw _unreadable;
    final version = decoded['version'];
    final build = decoded['build'];
    final notes = _httpsUri(decoded['notes']);
    if (version is! String || build is! int || notes == null) {
      throw _unreadable;
    }

    final downloads = decoded['downloads'];
    final key = switch (channel) {
      UpdateChannel.windowsInstaller => 'windows-setup',
      _ => null,
    };
    final entry = key != null && downloads is Map<String, Object?>
        ? downloads[key]
        : null;
    final download = _download(entry);
    if (channel.downloadsInstaller && download == null) throw _unreadable;

    return UpdateRelease(
      version: version,
      build: build,
      notesUrl: notes,
      download: download,
    );
  }

  /// Reads a release out of the decoded `version.json` of a web build.
  @visibleForTesting
  static UpdateRelease parseWebVersion(Object? decoded) {
    if (decoded is! Map<String, Object?>) throw _unreadable;
    final version = decoded['version'];
    final build = int.tryParse('${decoded['build_number']}');
    if (version is! String || build == null) throw _unreadable;
    return UpdateRelease(
      version: version,
      build: build,
      notesUrl: Uri.parse(AppInfo.releaseUrl(version)),
    );
  }

  static UpdateDownload? _download(Object? entry) {
    if (entry is! Map<String, Object?>) return null;
    final url = _httpsUri(entry['url']);
    final sha256 = entry['sha256'];
    final size = entry['size'];
    if (url == null || sha256 is! String || size is! int || size <= 0) {
      return null;
    }
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(sha256)) return null;
    return UpdateDownload(
      url: url,
      sha256: sha256.toLowerCase(),
      sizeBytes: size,
    );
  }

  /// Only `https` is followed - a manifest pointing anywhere else is not
  /// one this build will act on.
  static Uri? _httpsUri(Object? value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static const NetworkException _unreadable = NetworkException.because(
    AppErrorReason.updateCheckFailed,
  );
}

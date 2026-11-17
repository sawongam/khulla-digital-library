// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khulla/core/config/app_info.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/updates/data/http_update_manifest_data_source.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';

/// Reading `latest.json` - the file every installed copy will keep asking
/// for, in exactly the shape `release.yaml` writes it.
void main() {
  final sha = 'a' * 64;

  Map<String, Object?> manifest() => {
    'schema': 1,
    'version': '1.2.0',
    'build': 7,
    'notes': 'https://github.com/sawongam/khulla-digital-library/releases/tag/v1.2.0',
    'downloads': {
      'windows-setup': {
        'url': 'https://github.com/x/releases/download/v1.2.0/setup.exe',
        'sha256': sha,
        'size': 1024,
      },
      'linux': {
        'url': 'https://github.com/x/releases/download/v1.2.0/linux.tar.gz',
        'sha256': sha,
        'size': 2048,
      },
    },
  };

  group('parseManifest', () {
    test('reads the release and the Windows installer for that channel', () {
      final release = HttpUpdateManifestDataSource.parseManifest(
        manifest(),
        UpdateChannel.windowsInstaller,
      );

      expect(release.version, '1.2.0');
      expect(release.build, 7);
      expect(release.notesUrl.path, endsWith('/tag/v1.2.0'));
      expect(release.download!.fileName, 'setup.exe');
      expect(release.download!.sizeBytes, 1024);
      expect(release.download!.sha256, sha);
    });

    test('a channel that does not install in the app gets no download', () {
      final release = HttpUpdateManifestDataSource.parseManifest(
        manifest(),
        UpdateChannel.linux,
      );

      expect(release.version, '1.2.0');
      expect(release.download, isNull);
    });

    test('ignores fields it does not know, for manifests from later', () {
      final release = HttpUpdateManifestDataSource.parseManifest(
        {...manifest(), 'schema': 2, 'minimumBuild': 3, 'signature': 'x'},
        UpdateChannel.linux,
      );

      expect(release.build, 7);
    });

    test('refuses a manifest missing what every reader relies on', () {
      for (final broken in [
        null,
        <String, Object?>{},
        {...manifest(), 'build': '7'},
        {...manifest(), 'notes': 'http://example.com/insecure'},
      ]) {
        expect(
          () => HttpUpdateManifestDataSource.parseManifest(
            broken,
            UpdateChannel.linux,
          ),
          throwsA(isA<NetworkException>()),
        );
      }
    });

    test('refuses an installer it could not verify or would not fetch', () {
      for (final setup in [
        {'url': 'http://example.com/setup.exe', 'sha256': sha, 'size': 1},
        {'url': 'https://example.com/setup.exe', 'sha256': 'nope', 'size': 1},
        {'url': 'https://example.com/setup.exe', 'sha256': sha, 'size': 0},
      ]) {
        expect(
          () => HttpUpdateManifestDataSource.parseManifest({
            ...manifest(),
            'downloads': {'windows-setup': setup},
          }, UpdateChannel.windowsInstaller),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.reason,
              'reason',
              AppErrorReason.updateCheckFailed,
            ),
          ),
        );
      }
    });
  });

  test('parseWebVersion reads the version.json flutter build web writes', () {
    final release = HttpUpdateManifestDataSource.parseWebVersion({
      'app_name': 'khulla',
      'version': '1.2.0',
      'build_number': '7',
      'package_name': 'khulla',
    });

    expect(release.version, '1.2.0');
    expect(release.build, 7);
    expect(release.download, isNull);
  });

  group('fetchLatestRelease', () {
    test('asks for latest.json and reads it', () async {
      Uri? asked;
      final source = HttpUpdateManifestDataSource(
        MockClient((request) async {
          asked = request.url;
          return http.Response(jsonEncode(manifest()), 200);
        }),
      );

      final release = await source.fetchLatestRelease(UpdateChannel.linux);

      expect(asked, Uri.parse(AppInfo.latestReleaseManifestUrl));
      expect(release.build, 7);
    });

    test('offline, an error page, or a captive portal all read as '
        'updateCheckFailed', () async {
      for (final client in [
        MockClient((_) async => throw http.ClientException('offline')),
        MockClient((_) async => http.Response('Not Found', 404)),
        MockClient((_) async => http.Response('<html>Sign in</html>', 200)),
      ]) {
        await expectLater(
          HttpUpdateManifestDataSource(
            client,
          ).fetchLatestRelease(UpdateChannel.linux),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.reason,
              'reason',
              AppErrorReason.updateCheckFailed,
            ),
          ),
        );
      }
    });
  });
}

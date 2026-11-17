// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// How this particular install gets a newer version.
///
/// Decided by how Khulla was installed, not only by the operating system: the
/// Windows installer and the Windows portable zip run the same binary, but
/// only one of them has an installer that can be run again over the top.
enum UpdateChannel {
  /// Installed with `setup.exe`. The app downloads the next installer, checks
  /// it, and hands over to it - one click, no browser.
  windowsInstaller,

  /// Unzipped from the portable archive, possibly onto a USB stick. Replacing
  /// files where it happens to live is not safe, so the app only says a newer
  /// version exists and opens the download page.
  windowsPortable,

  /// Extracted from the Linux tarball. Same as [windowsPortable]: told, and
  /// pointed at the download page.
  linux,

  /// Installed from Google Play, which owns updating it. The GitHub release
  /// lands before Play has reviewed the same build, so asking GitHub would
  /// announce an update Play cannot deliver yet - this channel never checks,
  /// it only opens the store listing.
  googlePlay,

  /// The web build. The new version is already on the server; a reload is
  /// the whole update.
  web,

  /// macOS and iOS, which are built but not released. Nothing to check.
  unsupported;

  /// Whether this install asks for the latest version at all.
  bool get checksForUpdates => switch (this) {
    windowsInstaller || windowsPortable || linux || web => true,
    googlePlay || unsupported => false,
  };

  /// Whether the app applies the update itself rather than sending the
  /// operator to a download page.
  bool get installsInApp => switch (this) {
    windowsInstaller || web => true,
    windowsPortable || linux || googlePlay || unsupported => false,
  };

  /// Whether applying the update needs a file downloaded first.
  bool get downloadsInstaller => this == windowsInstaller;
}

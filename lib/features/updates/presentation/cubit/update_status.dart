// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Where the update flow stands.
///
/// Not a `LoadStatus`: this is a flow with several steps after the read, and
/// the dialog draws a different body and button for each.
enum UpdateStatus {
  /// Nothing asked yet this session.
  idle,

  /// Asking for the latest release.
  checking,

  /// The latest release is the one running.
  upToDate,

  /// A newer release exists and nothing has been done about it yet.
  available,

  /// Fetching the installer.
  downloading,

  /// The installer is downloaded and checked, waiting for the go-ahead.
  readyToInstall,

  /// Backing up and handing over. The process ends when this succeeds.
  installing,

  /// The last step failed; `error` says which and why.
  failed,
}

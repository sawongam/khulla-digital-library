// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Where one physical copy currently is.
///
/// This is the copy's own standing, not the title's: a title with four copies
/// can be simultaneously available, on loan and lost, which is exactly why
/// availability is counted from copies rather than stored on the title.
enum CopyStatus {
  available,
  onLoan,
  reserved,
  lost,
  damaged,
}

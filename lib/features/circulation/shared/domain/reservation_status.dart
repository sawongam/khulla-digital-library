// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Where one hold stands in the queue.
enum ReservationStatus {
  waiting,
  ready,
  fulfilled,
  expired,
  cancelled,
}

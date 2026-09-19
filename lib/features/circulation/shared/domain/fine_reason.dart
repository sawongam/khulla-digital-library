// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Why a fine was raised.
///
/// The reason is stored rather than inferred, because the rate that produced
/// the amount can change: a fine raised at last year's per-day rate must keep
/// reading as what it was.
enum FineReason { overdue, damage, lost, membership }

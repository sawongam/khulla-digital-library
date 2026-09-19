// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// A borrower's standing with the library.
///
/// [expiring] is separate from [active] because it is the state the desk can
/// still do something about: a membership that lapses next week is a
/// conversation at the counter today, not a refusal next month.
enum MemberStatus { active, expiring, expired, suspended }

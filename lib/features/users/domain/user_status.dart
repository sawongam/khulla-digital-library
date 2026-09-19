// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Whether a staff account can sign in today.
///
/// Disabling is preferred to deleting: the record is referenced by everything
/// the person did at the desk.
enum UserStatus { active, disabled }

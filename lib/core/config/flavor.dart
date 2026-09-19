// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// The build flavor the application is currently running as.
///
/// Each flavor has its own entrypoint (`lib/main_<flavor>.dart`) and resolves a
/// matching `AppConfig`.
enum Flavor { dev, prod }

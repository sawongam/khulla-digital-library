# khulla_ui

Khulla's design system: tokens, theme, and primitives. It is a separate package so the domain-free boundary is enforced at compile time - nothing in here may know about books, loans, or members.

```
lib/
├── khulla_ui.dart        # Public exports
└── src/
    ├── theme/            # AppTheme, AppColors, AppSpacing, AppRadius, AppMetrics, …
    ├── widgets/          # AppButton, AppSliverTable, AppFormModal, charts, …
    ├── icons/            # AppIcons + AppIcon - the only way to draw a glyph
    ├── extensions/       # context.appSpacing, context.appColors, …
    └── gallery/          # Dev-only component gallery
```

## Rules

- **Zero domain knowledge.** Widgets take ready-made strings - no `AppException`, no `l10n` imports. (The app side resolves those first, e.g. `ErrorRetryView` over `AppErrorView`.)
- **`App` prefix is reserved** for this package. Feature widgets take the feature's name instead.
- **Tokens only.** Read color, spacing, radius, type, and control heights from `context` (`appSpacing`, `appColors`, `appRadius`, `appMetrics`, `colorScheme`, `textTheme`). `app_palette.dart` is the only file in the repository allowed to contain a hex color, and it is not exported.
- **Icons** come from `AppIcons` and are drawn with `AppIcon` - one outline weight, selection carried by color. Never `Icons`/`CupertinoIcons`/`Icon` at a call site, never `SolarIcons` outside `app_icons.dart`.
- One public widget per file, filename matching the class in `snake_case`.

See [ADR 0006](../../docs/architecture/decisions/0006-khulla-ui-design-system.md) for why the package exists and [ADR 0009](../../docs/architecture/decisions/0009-adaptive-layout-shell.md) for the shell it serves.

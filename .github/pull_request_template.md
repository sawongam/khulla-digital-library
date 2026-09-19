## What this changes

<!-- One or two sentences. What a reviewer needs to know before reading the diff. -->

## Why

<!-- The problem, or a link to the issue: Closes #123 -->

## How to check it

<!-- The screens to open, the steps to take, the numbers to compare. -->

## Contributor License Agreement

<!-- Required once per contributor. Leave this line in to agree. -->

I have read the Contributor License Agreement in `CLA.md` and I agree to it for this and all my future contributions to Khulla Digital Library.

## Checklist

- [ ] `make check` passes locally (format, copyright, analyze, test)
- [ ] `make build` run, if a table, freezed state, domain model, DI annotation or asset changed
- [ ] `make migrate` run and the generated step filled in, if the schema changed
- [ ] `make localize` run, if an ARB key was added
- [ ] New user-facing text is in `lib/l10n/arb/app_en.arb`, not hard-coded
- [ ] New UI uses design tokens and `AppIcons` - no raw colors, spacing, radii or `Icons.*`
- [ ] Visual changes verified by running the app, or described above for the reviewer to check
- [ ] **Targeting `prod`?** `version:` in `pubspec.yaml` is bumped, build number included - merging publishes a release at that version

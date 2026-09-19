// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A preview of the library's uploaded mark, beside upload/remove controls.
///
/// Purely presentational - picking the file and calling the cubit is the
/// page's job, same split as every other form control here.
class SettingsLogoField extends StatelessWidget {
  const SettingsLogoField({
    required this.logoBytes,
    required this.isSaving,
    required this.onUpload,
    required this.onRemove,
    super.key,
  });

  /// The current mark's bytes, or null when none is set.
  final Uint8List? logoBytes;

  /// Disables both controls and shows the upload button's spinner while a
  /// change is in flight.
  final bool isSaving;

  final VoidCallback onUpload;

  /// Null when there is no logo to remove.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    final bytes = logoBytes;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: spacing.xlg * 2,
          height: spacing.xlg * 2,
          padding: EdgeInsets.all(spacing.xs),
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(radius.container),
            border: Border.all(color: colors.hairline),
          ),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.contain)
              : Center(
                  child: AppIcon(
                    AppIcons.upload,
                    size: spacing.lg,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsLibraryLogoHint,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: spacing.sm),
              Row(
                children: [
                  AppButton(
                    variant: AppButtonVariant.outline,
                    icon: AppIcons.upload,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : onUpload,
                    child: Text(l10n.settingsLibraryLogoUpload),
                  ),
                  if (onRemove != null) ...[
                    SizedBox(width: spacing.sm),
                    AppButton(
                      variant: AppButtonVariant.destructive,
                      onPressed: isSaving ? null : onRemove,
                      child: Text(l10n.settingsLibraryLogoRemove),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

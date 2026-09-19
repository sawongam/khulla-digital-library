// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Crops a freshly picked image before it becomes the shell's brand mark.
///
/// No fixed aspect ratio — the shell's brand mark renders whatever shape
/// comes out of this, so cropping is free-form rather than forced to a
/// square.
///
/// `crop_your_image` rather than `image_cropper`: the latter opens a native
/// iOS/Android crop screen that doesn't exist on Windows or web, this app's
/// primary targets. This one is a pure Flutter widget, so it runs the same
/// everywhere.
class SettingsLogoCropDialog extends StatefulWidget {
  const SettingsLogoCropDialog({required this.imageBytes, super.key});

  /// The picked file's raw bytes, not yet cropped.
  final Uint8List imageBytes;

  /// Opens the dialog. Resolves to the cropped bytes, or null on cancel.
  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
  }) => AppFormModal.show<Uint8List>(
    context: context,
    builder: (_) => SettingsLogoCropDialog(imageBytes: imageBytes),
  );

  @override
  State<SettingsLogoCropDialog> createState() => _SettingsLogoCropDialogState();
}

class _SettingsLogoCropDialogState extends State<SettingsLogoCropDialog> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        setState(() => _isCropping = false);
        AppToast.error(context, message: context.l10n.errorUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final l10n = context.l10n;

    return AppFormModal(
      title: l10n.settingsLibraryLogoCropTitle,
      description: l10n.settingsLibraryLogoCropDescription,
      width: AppDialogWidth.lg,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.commonApply,
          isLoading: _isCropping,
          onPressed: () {
            setState(() => _isCropping = true);
            _controller.crop();
          },
        ),
      ],
      children: [
        SizedBox(
          height: 320,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.hairline),
              borderRadius: BorderRadius.circular(context.appRadius.container),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.appRadius.container),
              child: Crop(
                image: widget.imageBytes,
                controller: _controller,
                interactive: true,
                baseColor: scheme.surface,
                maskColor: scheme.scrim.withValues(alpha: 0.6),
                progressIndicator: const Center(child: AppSpinner()),
                onCropped: _onCropped,
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        Text(
          l10n.settingsLibraryLogoCropHint,
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

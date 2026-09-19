// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Mixes a brand color, and hands it back on confirm.
///
/// The choice is applied on confirm rather than live under the picker: the
/// dialog would be repainting itself — its own buttons, its own field borders
/// — on every drag frame, which makes judging a color impossible. The preview
/// strip stands in for that instead.
class SettingsBrandColorDialog extends StatefulWidget {
  const SettingsBrandColorDialog({required this.initial, super.key});

  /// The color the picker opens on — whatever the brand is now.
  final Color initial;

  /// Opens the dialog. Resolves to the chosen color, or null on cancel.
  static Future<Color?> show(BuildContext context, {required Color initial}) =>
      AppFormModal.show<Color>(
        context: context,
        builder: (_) => SettingsBrandColorDialog(initial: initial),
      );

  @override
  State<SettingsBrandColorDialog> createState() =>
      _SettingsBrandColorDialogState();
}

class _SettingsBrandColorDialogState extends State<SettingsBrandColorDialog> {
  late Color _color = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return AppFormModal(
      title: l10n.settingsAppearanceBrandCustomTitle,
      description: l10n.settingsAppearanceBrandCustomDescription,
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
          onPressed: () => Navigator.of(context).pop(_color),
        ),
      ],
      children: [
        AppColorPicker(
          value: _color,
          hexLabel: l10n.fieldColorHex,
          onChanged: (color) => setState(() => _color = color),
        ),
        SizedBox(height: spacing.md),
        _Preview(seed: _color),
      ],
    );
  }
}

/// What the color will actually look like in the product: a filled button, a
/// tinted row and the deep emphasis ink, drawn from the derived ramp rather
/// than from the raw seed. A swatch alone hides the two failures that matter
/// — ink that vanishes on the fill, and a tint that turns muddy.
class _Preview extends StatelessWidget {
  const _Preview({required this.seed});

  final Color seed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final colors = context.appColors;
    final typography = context.appTextStyles;
    final brand = AppBrand.fromSeed(seed);

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: brand.tintFaint,
        borderRadius: BorderRadius.circular(radius.container),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.sm,
              vertical: spacing.xs,
            ),
            decoration: BoxDecoration(
              color: brand.seed,
              borderRadius: BorderRadius.circular(radius.container),
            ),
            child: Text(
              l10n.settingsAppearanceBrandPreviewAction,
              style: typography.button.copyWith(color: brand.onBrand),
            ),
          ),
          SizedBox(width: spacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.sm,
              vertical: spacing.xs,
            ),
            decoration: BoxDecoration(
              color: brand.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(radius.container),
            ),
            child: Text(
              l10n.settingsAppearanceBrandPreviewSelected,
              style: typography.label.copyWith(color: brand.deep),
            ),
          ),
        ],
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:khulla_ui/khulla_ui.dart';

/// The gallery's surfaces section: cards, badges and overlays.
///
/// Owns its demo state (the bottom sheet's radio) and the overlay helpers
/// so the gallery shell stays a thin section switch.
class AppGallerySurfaces extends StatefulWidget {
  const AppGallerySurfaces({super.key});

  @override
  State<AppGallerySurfaces> createState() => _AppGallerySurfacesState();
}

class _AppGallerySurfacesState extends State<AppGallerySurfaces> {
  String _radio = 'spine';

  Widget _cardBody(String label) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.appTextStyles.sectionTitle.copyWith(
            color: colors.ink100,
          ),
        ),
        SizedBox(height: spacing.xxs),
        Text(
          'Depth here comes from the hairline, not from a drop shadow.',
          style: context.appTextStyles.body.copyWith(
            color: colors.mutedForeground,
          ),
        ),
      ],
    );
  }

  void _showDialog() {
    unawaited(
      AppDialog.confirmDestructive(
        context: context,
        title: 'Delete this copy?',
        message:
            'Copy C-00841 will be removed from the catalogue. Its loan history '
            'stays on the member record.',
        confirmLabel: 'Delete copy',
        cancelLabel: 'Keep it',
      ),
    );
  }

  void _showSideSheet() {
    unawaited(
      AppSideSheet.show<void>(
        context: context,
        title: 'Edit title',
        caption: 'Changes are saved to the catalogue immediately.',
        closeTooltip: 'Close',
        builder: (sheetContext) => Column(
          children: [
            AppTextField(
              label: 'Title',
              initialValue: 'The Dispossessed',
              onChanged: (_) {},
            ),
            SizedBox(height: sheetContext.appMetrics.formRowGap),
            AppTextField(
              label: 'Author',
              initialValue: 'Ursula K. Le Guin',
              onChanged: (_) {},
            ),
          ],
        ),
        actionsBuilder: (sheetContext) => AppDialogActions(
          children: [
            AppDialog.secondaryAction(
              context: sheetContext,
              label: 'Cancel',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
            AppDialog.primaryAction(
              context: sheetContext,
              label: 'Save',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet() {
    unawaited(
      AppBottomSheet.show<void>(
        context: context,
        title: 'Label size',
        caption: 'Applies to every label in this print run.',
        builder: (sheetContext) => AppSegmentedControl<String>(
          value: _radio,
          items: const ['spine', 'pocket'],
          itemLabel: (option) => option[0].toUpperCase() + option.substring(1),
          expand: true,
          onChanged: (value) {
            setState(() => _radio = value);
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return AppGalleryStack(
      children: [
        AppGallerySection(
          title: 'Cards',
          note:
              'The default card is a bordered block: hairline, 6px corners, no '
              'fill and no shadow. `filled` is the rarer variant.',
          children: [
            AppGalleryRow(
              label: 'variants',
              children: [
                SizedBox(
                  width: 260,
                  child: AppCard(child: _cardBody('Bordered block')),
                ),
                SizedBox(
                  width: 260,
                  child: AppCard(
                    filled: true,
                    child: _cardBody('Filled'),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: AppCard(
                    onTap: () {},
                    child: _cardBody('Tappable - hover it'),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: AppCard(
                    tone: AppStatusTone.warning,
                    child: _cardBody('Toned'),
                  ),
                ),
              ],
            ),
          ],
        ),
        AppGallerySection(
          title: 'Badges',
          note:
              'Ink on a secondary wash; danger keeps a red wash. 10px semibold, '
              'deliberately small.',
          children: [
            AppGalleryRow(
              label: 'tones',
              children: [
                for (final (label, tone) in const <(String, AppStatusTone)>[
                  ('Available', AppStatusTone.success),
                  ('Due today', AppStatusTone.warning),
                  ('Reserved', AppStatusTone.info),
                  ('Overdue', AppStatusTone.danger),
                  ('Draft', AppStatusTone.neutral),
                  ('Featured', AppStatusTone.brand),
                ])
                  AppStatusBadge(label: label, tone: tone),
              ],
            ),
            const AppGalleryRow(
              label: 'dense, alarm wash, and with an icon',
              children: [
                AppStatusBadge(
                  label: 'On loan',
                  tone: AppStatusTone.info,
                  dense: true,
                ),
                AppStatusBadge(
                  label: 'Lost',
                  tone: AppStatusTone.danger,
                ),
                AppStatusBadge(
                  label: 'Returned',
                  tone: AppStatusTone.success,
                  icon: AppIcons.check,
                ),
              ],
            ),
          ],
        ),
        AppGallerySection(
          title: 'Overlays',
          note:
              'Open the dialog and hover its close chip - it drifts outward and '
              'turns the glyph a quarter turn.',
          children: [
            AppGalleryRow(
              label: 'open one',
              children: [
                AppButton(
                  onPressed: _showDialog,
                  variant: AppButtonVariant.outline,
                  child: const Text('Confirmation dialog'),
                ),
                AppButton(
                  onPressed: _showSideSheet,
                  variant: AppButtonVariant.outline,
                  child: const Text('Side sheet'),
                ),
                AppButton(
                  onPressed: _showBottomSheet,
                  variant: AppButtonVariant.outline,
                  child: const Text('Bottom sheet'),
                ),
                Tooltip(
                  message: 'A light tooltip with a hairline, not a dark slab',
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.sm,
                      vertical: spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.hairline),
                      borderRadius: BorderRadius.circular(
                        context.appRadius.container,
                      ),
                    ),
                    child: Text(
                      'Hover for a tooltip',
                      style: context.appTextStyles.body.copyWith(
                        color: colors.ink500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The gallery's foundations section: type, color, shape and depth.
///
/// Stateless and self-contained - the specimens name tokens, not product
/// concepts, so nothing here is localized.
class AppGalleryFoundations extends StatelessWidget {
  const AppGalleryFoundations({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final type = context.appTextStyles;
    final radius = context.appRadius;
    final spacing = context.appSpacing;

    return AppGalleryStack(
      children: [
        AppGallerySection(
          title: 'Type',
          note:
              'Every size is a pair - the second value applies from 1600px. '
              'There are no rungs between them.',
          children: [
            for (final (name, style) in <(String, TextStyle)>[
              ('displayMedium', type.displayMedium),
              ('displaySmall', type.displaySmall),
              ('formTitle', type.formTitle),
              ('pageHeader', type.pageHeader),
              ('title', type.title),
              ('sectionTitle', type.sectionTitle),
              ('columnHeader', type.columnHeader),
              ('bodyLarge', type.bodyLarge),
              ('body', type.body),
              ('label', type.label),
              ('caption', type.caption),
              ('micro', type.micro),
            ])
              Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        '$name ${style.fontSize?.round()}',
                        style: type.micro.copyWith(color: colors.ink600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'The catalogue holds 12,480 titles',
                        style: style.copyWith(color: colors.ink100),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        AppGallerySection(
          title: 'Color',
          note:
              'One saturated hue. Everything else is ink, a hairline, or an '
              'alpha tint of one of them.',
          children: [
            AppGalleryRow(
              label: 'brand and status',
              children: [
                AppGallerySwatch(name: 'brand', color: colors.brand),
                AppGallerySwatch(name: 'success', color: colors.success),
                AppGallerySwatch(name: 'warning', color: colors.warning),
                AppGallerySwatch(name: 'info', color: colors.info),
                AppGallerySwatch(name: 'danger', color: colors.danger),
                AppGallerySwatch(name: 'premium', color: colors.premium),
              ],
            ),
            AppGalleryRow(
              label: 'ink ramp',
              children: [
                AppGallerySwatch(name: 'ink100', color: colors.ink100),
                AppGallerySwatch(name: 'ink200', color: colors.ink200),
                AppGallerySwatch(name: 'ink300', color: colors.ink300),
                AppGallerySwatch(name: 'ink400', color: colors.ink400),
                AppGallerySwatch(name: 'ink500', color: colors.ink500),
                AppGallerySwatch(name: 'ink600', color: colors.ink600),
                AppGallerySwatch(name: 'hairline', color: colors.hairline),
              ],
            ),
            AppGalleryRow(
              label: 'tints - every interactive surface in the product',
              children: [
                AppGallerySwatch(name: 'navRow', color: colors.tints.navRow),
                AppGallerySwatch(
                  name: 'rowSelected',
                  color: colors.tints.rowSelected,
                ),
                AppGallerySwatch(
                  name: 'rowZebra',
                  color: colors.tints.rowZebra,
                ),
                AppGallerySwatch(
                  name: 'rowHover',
                  color: colors.tints.rowHover,
                ),
                AppGallerySwatch(
                  name: 'tableHeader',
                  color: colors.tints.tableHeader,
                ),
                AppGallerySwatch(
                  name: 'filterActive',
                  color: colors.tints.filterActive,
                ),
              ],
            ),
          ],
        ),
        AppGallerySection(
          title: 'Shape and depth',
          note:
              'Controls are rounder than containers, and items inside a '
              'container are sharper than it. Shadows stay shallow.',
          children: [
            AppGalleryRow(
              label: 'radius',
              children: [
                AppGalleryRadiusSpecimen(name: 'item', value: radius.item),
                AppGalleryRadiusSpecimen(
                  name: 'container',
                  value: radius.container,
                ),
                AppGalleryRadiusSpecimen(
                  name: 'control',
                  value: radius.control,
                ),
                AppGalleryRadiusSpecimen(name: 'sheet', value: radius.sheet),
              ],
            ),
            AppGalleryRow(
              label: 'elevation',
              children: [
                AppGalleryShadowSpecimen(
                  name: 'card',
                  shadow: context.appShadows.card,
                ),
                AppGalleryShadowSpecimen(
                  name: 'raised',
                  shadow: context.appShadows.raised,
                ),
                AppGalleryShadowSpecimen(
                  name: 'overlay',
                  shadow: context.appShadows.overlay,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

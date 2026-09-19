// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_design_gallery}
/// The design system's own reference screen: every component, in every state
/// that matters, on one page.
///
/// It exists to be *looked at*. When a component is retuned, this is where the
/// change is checked - side by side with its neighbours, at both densities,
/// in both themes - rather than by opening whichever product screen happens
/// to use it. A component that cannot be shown here without a special case is
/// usually a component that has grown a screen-specific behaviour it should
/// not have.
///
/// Development only. It is registered on a route the release build does not
/// declare, and its copy is intentionally not localized: the labels name
/// tokens and variants, not product concepts.
/// {@endtemplate}
class AppDesignGallery extends StatefulWidget {
  /// {@macro app_design_gallery}
  const AppDesignGallery({super.key});

  @override
  State<AppDesignGallery> createState() => _AppDesignGalleryState();
}

class _AppDesignGalleryState extends State<AppDesignGallery> {
  _GallerySection _section = _GallerySection.foundations;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final metrics = context.appMetrics;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.page,
                spacing.pageVertical,
                spacing.page,
                spacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Design system',
                          style: context.appTextStyles.pageHeader.copyWith(
                            color: colors.ink100,
                          ),
                        ),
                        Text(
                          'Density: ${metrics.density.name} · '
                          'body ${context.appTextStyles.body.fontSize?.round()}px · '
                          'field ${metrics.fieldHeight.round()}px',
                          style: context.appTextStyles.body.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSegmentedControl<_GallerySection>(
                    value: _section,
                    items: _GallerySection.values,
                    itemLabel: (value) => value.label,
                    onChanged: (value) => setState(() => _section = value),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  spacing.page,
                  spacing.lg,
                  spacing.page,
                  spacing.xxlg,
                ),
                child: switch (_section) {
                  _GallerySection.foundations => const AppGalleryFoundations(),
                  _GallerySection.controls => const AppGalleryControls(),
                  _GallerySection.surfaces => const AppGallerySurfaces(),
                  _GallerySection.data => const AppGalleryData(),
                  _GallerySection.states => const AppGalleryStates(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gallery's own sections.
enum _GallerySection {
  foundations('Foundations'),
  controls('Controls'),
  surfaces('Surfaces'),
  data('Data'),
  states('States');

  _GallerySection(this.label);

  final String label;
}

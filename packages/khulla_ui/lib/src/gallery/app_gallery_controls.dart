// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The gallery's controls section: buttons, fields and filters.
///
/// Owns its demo state (controllers, toggles, the loading flag) so the
/// gallery shell stays a thin section switch.
class AppGalleryControls extends StatefulWidget {
  const AppGalleryControls({super.key});

  @override
  State<AppGalleryControls> createState() => _AppGalleryControlsState();
}

class _AppGalleryControlsState extends State<AppGalleryControls> {
  final _searchController = TextEditingController();
  final _textController = TextEditingController(text: 'Ursula K. Le Guin');
  final _quantityController = TextEditingController(text: '1');

  bool _checkbox = true;
  bool _switch = true;
  String _radio = 'spine';
  String? _dropdown = 'Fiction';
  bool _filter = true;
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppGalleryStack(
      children: [
        AppGallerySection(
          title: 'Buttons',
          note:
              'Default is 36px. Destructive is outlined, never filled. Press '
              'one to see the ripple and the 0.95 dip.',
          children: [
            AppGalleryRow(
              label: 'variants',
              children: [
                AppButton(onPressed: () {}, child: const Text('Primary')),
                AppButton(
                  onPressed: () {},
                  variant: AppButtonVariant.destructive,
                  child: const Text('Delete copy'),
                ),
                AppButton(
                  onPressed: () {},
                  variant: AppButtonVariant.outline,
                  child: const Text('Cancel'),
                ),
                AppButton(
                  onPressed: () {},
                  variant: AppButtonVariant.secondary,
                  child: const Text('Secondary'),
                ),
                AppButton(
                  onPressed: () {},
                  variant: AppButtonVariant.ghost,
                  child: const Text('Clear filters'),
                ),
                AppButton(
                  onPressed: () {},
                  variant: AppButtonVariant.success,
                  child: const Text('Mark returned'),
                ),
                AppButton(
                  onPressed: () {},
                  variant: AppButtonVariant.link,
                  child: const Text('View all'),
                ),
              ],
            ),
            AppGalleryRow(
              label: 'sizes and glyphs',
              children: [
                AppButton(
                  onPressed: () {},
                  icon: AppIcons.add,
                  child: const Text('Add title'),
                ),
                AppButton(
                  onPressed: () {},
                  size: AppButtonSize.medium,
                  child: const Text('Medium'),
                ),
                AppButton(
                  onPressed: () {},
                  size: AppButtonSize.large,
                  trailingIcon: AppIcons.arrowRight,
                  child: const Text('Large'),
                ),
              ],
            ),
            AppGalleryRow(
              label: 'states',
              children: [
                AppButton(
                  onPressed: () => setState(() => _loading = !_loading),
                  isLoading: _loading,
                  child: const Text('Save changes'),
                ),
                const AppButton(onPressed: null, child: Text('Disabled')),
                const AppButton(
                  onPressed: null,
                  variant: AppButtonVariant.outline,
                  child: Text('Disabled outline'),
                ),
              ],
            ),
            AppGalleryRow(
              label: 'icon buttons',
              children: [
                AppIconButton(
                  icon: AppIcons.edit,
                  tooltip: 'Edit',
                  size: AppIconButtonSize.small,
                  onPressed: () {},
                ),
                AppIconButton(
                  icon: AppIcons.printer,
                  tooltip: 'Print labels',
                  onPressed: () {},
                ),
                AppIconButton(
                  icon: AppIcons.notifications,
                  tooltip: 'Notifications',
                  size: AppIconButtonSize.large,
                  badge: true,
                  onPressed: () {},
                ),
                AppMenuButton(
                  tooltip: 'More actions',
                  actions: [
                    AppMenuAction(
                      label: 'View',
                      icon: AppIcons.preview,
                      onSelected: () {},
                    ),
                    AppMenuAction(
                      label: 'Edit',
                      icon: AppIcons.edit,
                      onSelected: () {},
                    ),
                    AppMenuAction(
                      label: 'Delete',
                      icon: AppIcons.delete,
                      isDestructive: true,
                      onSelected: () {},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AppGallerySection(
          title: 'Fields',
          note:
              'Focus a field: the text nudges 2px right over 300ms and no ring '
              'appears. On error the label turns red, not the border.',
          children: [
            AppGalleryFieldGrid(
              children: [
                AppTextField(
                  label: 'Author',
                  controller: _textController,
                  required: true,
                  onChanged: (_) {},
                ),
                AppTextField(
                  label: 'ISBN',
                  hintText: '978-0-000-00000-0',
                  errorText: 'That ISBN is already on another title.',
                  onChanged: (_) {},
                ),
                AppDropdownField<String>(
                  label: 'Collection',
                  value: _dropdown,
                  items: const [
                    'Fiction',
                    'Reference',
                    'Periodicals',
                    'Local history',
                    'Children',
                    'Young adult',
                    'Reserve',
                  ],
                  itemLabel: (value) => value,
                  footerActionLabel: 'Add collection',
                  onFooterAction: () {},
                  onChanged: (value) => setState(() => _dropdown = value),
                ),
                AppSearchField(
                  hintText: 'Search titles, authors, ISBNs',
                  controller: _searchController,
                  clearTooltip: 'Clear',
                  onChanged: (_) {},
                ),
                AppQuantityField(
                  label: 'Copies',
                  required: true,
                  controller: _quantityController,
                  decreaseTooltip: 'One fewer',
                  increaseTooltip: 'One more',
                  onChanged: (_) {},
                ),
              ],
            ),
            AppGalleryRow(
              label: 'toggles',
              children: [
                SizedBox(
                  width: 260,
                  child: AppCheckboxField(
                    value: _checkbox,
                    label: 'Reservable',
                    description: 'Members may place a hold on this title.',
                    onChanged: (value) =>
                        setState(() => _checkbox = value ?? false),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: AppSwitchField(
                    value: _switch,
                    label: 'Overdue notices',
                    description: 'Send a notice the morning a loan falls due.',
                    onChanged: (value) => setState(() => _switch = value),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: AppSegmentedControl<String>(
                    value: _radio,
                    items: const ['spine', 'pocket'],
                    itemLabel: (option) =>
                        option[0].toUpperCase() + option.substring(1),
                    expand: true,
                    onChanged: (value) => setState(() => _radio = value),
                  ),
                ),
              ],
            ),
            AppGalleryRow(
              label: 'filters - hairline at rest, brand wash when set',
              children: [
                AppFilterChip(
                  label: 'Overdue',
                  count: 12,
                  selected: _filter,
                  tone: AppStatusTone.danger,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                AppFilterChip(
                  label: 'On loan',
                  count: 48,
                  selected: false,
                  onSelected: (_) {},
                ),
                AppFilterChip(
                  label: 'Reserved',
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

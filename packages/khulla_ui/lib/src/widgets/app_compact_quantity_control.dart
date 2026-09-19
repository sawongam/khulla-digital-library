// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The tighter minus/plus control behind [AppQuantityField] at
/// [AppQuantityFieldSize.small]: a bordered pill with icon buttons at both
/// ends and the figure - sliding while unfocused - in the middle.
class AppCompactQuantityControl extends StatelessWidget {
  const AppCompactQuantityControl({
    required this.controlHeight,
    required this.canDecrease,
    required this.canIncrease,
    required this.showSlide,
    required this.parsed,
    required this.numeric,
    required this.colors,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.max,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  final double controlHeight;
  final bool canDecrease;
  final bool canIncrease;
  final bool showSlide;
  final int? parsed;
  final TextStyle numeric;
  final AppColors colors;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final int max;
  final String decreaseTooltip;
  final String increaseTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey('app_quantity_control'),
      constraints: BoxConstraints.tightFor(height: controlHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.appRadius.container),
          border: Border.all(
            color: colors.hairline,
            width: context.appBorders.hairline,
          ),
        ),
        child: Row(
          children: [
            AppIconButton(
              icon: AppIcons.remove,
              tooltip: decreaseTooltip,
              size: AppIconButtonSize.small,
              onPressed: canDecrease ? onDecrease : null,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [AppPositiveIntFormatter(max: max)],
                    style: numeric.copyWith(
                      color: showSlide ? Colors.transparent : colors.ink100,
                    ),
                    cursorColor: colors.ink100,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    onChanged: onChanged,
                  ),
                  if (showSlide)
                    IgnorePointer(
                      child: AppSlidingNumber(
                        value: parsed!,
                        style: numeric,
                      ),
                    ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcons.add,
              tooltip: increaseTooltip,
              size: AppIconButtonSize.small,
              onPressed: canIncrease ? onIncrease : null,
            ),
          ],
        ),
      ),
    );
  }
}

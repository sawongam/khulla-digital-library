// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla_ui/khulla_ui.dart';

final _destinations = <AppNavDestination>[
  const AppNavDestination(icon: AppIcon(AppIcons.book), label: 'First'),
  const AppNavDestination(icon: AppIcon(AppIcons.people), label: 'Second'),
];

/// `find.byIcon` only knows Material's `Icon`; the app draws `AppIcon`.
Finder _icon(AppIconSpec spec) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.spec == spec,
);

Widget _host(Widget child, {Size size = const Size(1400, 900)}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Row(
        children: [
          child,
          const Expanded(child: SizedBox()),
        ],
      ),
    ),
  ),
);

void main() {
  group('AppNavRail', () {
    testWidgets('lays out collapsed with a bottom-pinned trailing slot', (
      tester,
    ) async {
      // The trailing slot wraps its child in Expanded to push it to the
      // bottom of the rail. That only works if NavigationRail puts trailing
      // inside a Flex - if a future Flutter moves it into a scroll view,
      // this test fails loudly instead of the app throwing at runtime.
      await tester.pumpWidget(
        _host(
          AppNavRail(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: _destinations,
            leading: const AppIcon(AppIcons.library),
            trailing: const AppIcon(AppIcons.settings),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Collapsed, a destination is its glyph and a tooltip - the label is
      // not painted, which is the whole point of the narrow rail.
      expect(_icon(AppIcons.book), findsOneWidget);
      expect(find.text('First'), findsNothing);
      expect(
        find.byTooltip('First'),
        findsOneWidget,
        reason: 'a collapsed destination must still name itself on hover',
      );
      expect(_icon(AppIcons.settings), findsOneWidget);
    });

    testWidgets('lays out extended', (tester) async {
      await tester.pumpWidget(
        _host(
          AppNavRail(
            selectedIndex: 1,
            onDestinationSelected: (_) {},
            destinations: _destinations,
            extended: true,
            trailing: const AppIcon(AppIcons.settings),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('reports the tapped destination index', (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        _host(
          AppNavRail(
            selectedIndex: 0,
            onDestinationSelected: (index) => selected = index,
            destinations: _destinations,
          ),
        ),
      );

      await tester.tap(_icon(AppIcons.people));
      expect(selected, 1);
    });
  });

  group('AppNavBar', () {
    testWidgets('renders every destination and reports taps', (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              selectedIndex: 0,
              onDestinationSelected: (index) => selected = index,
              destinations: _destinations,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      await tester.tap(find.text('Second'));
      expect(selected, 1);
    });

    testWidgets('fits five destinations on a 360px phone', (tester) async {
      // The shell fills the bar with four sections plus *More*, and the
      // narrowest window the product supports is 360px - about 64px a slot.
      // Any label or glyph that outgrows that overflows on a real phone
      // rather than ellipsing, which is what this pins.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [
                AppNavDestination(
                  icon: AppIcon(AppIcons.gridView),
                  label: 'Dashboard',
                ),
                AppNavDestination(
                  icon: AppIcon(AppIcons.book),
                  label: 'Catalogue',
                ),
                AppNavDestination(
                  icon: AppIcon(AppIcons.transfer),
                  label: 'Circulation',
                ),
                AppNavDestination(
                  icon: AppIcon(AppIcons.people),
                  label: 'Members',
                ),
                AppNavDestination(
                  icon: AppIcon(AppIcons.gridView),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The bar is chrome, not content. Past about a fifth of a 640px phone
      // it starts eating the list it is there to navigate.
      expect(
        tester.getSize(find.byType(AppNavBar)).height,
        lessThanOrEqualTo(72),
      );
    });
  });

  group('AppDialogActions', () {
    testWidgets('keeps both buttons on one row on a phone', (tester) async {
      // Stacked full-width buttons cost a band of height on the screen with
      // the least of it, and read as two unrelated controls rather than as a
      // choice. Both buttons share one row, clustered at the trailing edge.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppDialogActions(
              children: [
                AppButton(onPressed: () {}, child: const Text('Cancel')),
                AppButton(onPressed: () {}, child: const Text('Save')),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(AppDialogActions));
      final cancel = tester.getRect(find.byType(AppButton).first);
      final save = tester.getRect(find.byType(AppButton).last);
      expect(cancel.top, save.top);
      expect(cancel.right, lessThanOrEqualTo(save.left));
      expect(save.right, closeTo(row.right, 1));
    });
  });
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/features/guide/presentation/guide_article_page.dart';
import 'package:khulla/features/guide/presentation/guide_page.dart';
import 'package:khulla/l10n/gen/app_localizations.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Every width the shell renders at, so a layout that only holds together on
/// a desktop window fails here rather than on a librarian's phone.
const _sizes = <String, Size>{
  'phone': Size(390, 844),
  'tablet': Size(834, 1112),
  'desktop': Size(1440, 900),
};

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(child, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  group('GuidePage', () {
    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      testWidgets('lays out on a $name without overflowing', (tester) async {
        await _pumpAt(tester, size, const GuidePage());
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('GuideArticlePage', () {
    // Every article at every width: the diagrams, term tables and pager each
    // reflow differently, and a layout assert in one article is invisible
    // from the others.
    for (final topic in GuideTopic.values) {
      for (final MapEntry(key: name, value: size) in _sizes.entries) {
        testWidgets('${topic.slug} lays out on a $name', (tester) async {
          await _pumpAt(tester, size, GuideArticlePage(topic: topic));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('renders in Nepali as well as English', (tester) async {
      await _pumpAt(
        tester,
        _sizes['desktop']!,
        const GuideArticlePage(topic: GuideTopic.circulation),
        locale: const Locale('ne'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a slug that names nothing renders the not-found state', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _sizes['desktop']!,
        const GuideArticlePage(topic: null),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppEmptyView), findsOneWidget);
    });
  });
}

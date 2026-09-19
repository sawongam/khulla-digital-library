// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/shared/utils/collection_page_size.dart';
import 'package:khulla_ui/khulla_ui.dart';

void main() {
  group('computeCollectionPageSize', () {
    final metrics = AppMetrics.of(AppDensity.compact);

    // Heights are derived from the metrics rather than written out, because
    // row height is a design token that gets tuned. A literal here turns any
    // visual adjustment into a red test about a number nobody promised.
    test('subtracts the header and rounds up row slots', () {
      final exactly14Rows =
          metrics.tableHeaderHeight + 14 * metrics.tableRowHeight;

      expect(
        computeCollectionPageSize(
          tableBodyHeight: exactly14Rows,
          metrics: metrics,
        ),
        14,
      );
    });

    test('rounds up when the viewport fits a partial row', () {
      final fourteenRowsAndASliver =
          metrics.tableHeaderHeight + 14.2 * metrics.tableRowHeight;

      expect(
        computeCollectionPageSize(
          tableBodyHeight: fourteenRowsAndASliver,
          metrics: metrics,
        ),
        15,
      );
    });

    test('never goes below the minimum', () {
      expect(
        computeCollectionPageSize(
          tableBodyHeight: 10,
          metrics: metrics,
        ),
        kCollectionPageSizeMin,
      );
    });
  });
}

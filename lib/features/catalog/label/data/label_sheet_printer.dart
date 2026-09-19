// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/label/domain/models/label_queue_entry.dart';
import 'package:khulla/features/catalog/label/domain/models/label_size.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds the label sheet PDF and hands it to the operating system.
///
/// A4 with fixed margins; the queued stickers flow across as many pages as
/// they need. Barcodes are real Code 128 — the preview's drawn bars answer
/// layout questions, this answers the scanner's.
///
/// Returns whether the sheet reached the OS print dialog. A dismissed dialog
/// is not an error, so it answers `false` rather than throwing.
@lazySingleton
class LabelSheetPrinter {
  static const double _marginMm = 10;
  static const double _gapMm = 3;

  Future<bool> printSheet({
    required List<LabelQueueEntry> queue,
    required LabelSize size,
    required bool includeTitle,
    required bool includeAuthor,
    required bool includeShelf,
    required String? libraryName,
  }) async {
    final cells = [
      for (final entry in queue)
        for (var i = 0; i < entry.count; i++) entry,
    ];
    if (cells.isEmpty) return false;
    try {
      return await Printing.layoutPdf(
        name: 'khulla-labels.pdf',
        onLayout: (format) => _buildSheet(
          format: format,
          cells: cells,
          size: size,
          includeTitle: includeTitle,
          includeAuthor: includeAuthor,
          includeShelf: includeShelf,
          libraryName: libraryName,
        ),
      );
    } on AppException {
      rethrow;
    } on Object {
      throw const StorageException('The label sheet could not be printed.');
    }
  }

  Future<Uint8List> _buildSheet({
    required PdfPageFormat format,
    required List<LabelQueueEntry> cells,
    required LabelSize size,
    required bool includeTitle,
    required bool includeAuthor,
    required bool includeShelf,
    required String? libraryName,
  }) {
    const mm = PdfPageFormat.mm;
    final labelWidth = size.mmWidth * mm;
    final labelHeight = size.mmHeight * mm;
    final usableWidth = format.width - 2 * _marginMm * mm;
    final usableHeight = format.height - 2 * _marginMm * mm;

    final columns = ((usableWidth + _gapMm * mm) ~/ (labelWidth + _gapMm * mm))
        .clamp(
          1,
          cells.length,
        );
    final rows = ((usableHeight + _gapMm * mm) ~/ (labelHeight + _gapMm * mm))
        .clamp(
          1,
          cells.length,
        );
    final perPage = columns * rows;

    final doc = pw.Document();
    for (var page = 0; page * perPage < cells.length; page++) {
      final pageCells = cells.skip(page * perPage).take(perPage).toList();
      doc.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(_marginMm * mm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var row = 0; row * columns < pageCells.length; row++) ...[
                  if (row > 0) pw.SizedBox(height: _gapMm * mm),
                  pw.Row(
                    children: [
                      for (var column = 0; column < columns; column++)
                        if (row * columns + column < pageCells.length) ...[
                          if (column > 0) pw.SizedBox(width: _gapMm * mm),
                          _labelCell(
                            entry: pageCells[row * columns + column],
                            size: size,
                            includeTitle: includeTitle,
                            includeAuthor: includeAuthor,
                            includeShelf: includeShelf,
                            libraryName: libraryName,
                          ),
                        ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return doc.save();
  }

  pw.Widget _labelCell({
    required LabelQueueEntry entry,
    required LabelSize size,
    required bool includeTitle,
    required bool includeAuthor,
    required bool includeShelf,
    required String? libraryName,
  }) {
    const mm = PdfPageFormat.mm;
    final base = size == LabelSize.small ? 5.0 : 6.0;

    final library = libraryName?.trim();
    final title = includeTitle ? entry.copy.titleName.trim() : '';
    final author = includeAuthor ? (entry.author ?? '').trim() : '';
    final shelf = includeShelf ? entry.copy.shelf.trim() : '';
    final barcode = entry.copy.barcode.isEmpty ? '-' : entry.copy.barcode;

    pw.Widget text(String value, {bool bold = false, double delta = 0}) =>
        pw.Text(
          value,
          maxLines: 1,
          style: pw.TextStyle(
            font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
            fontSize: base + delta,
            color: PdfColors.black,
          ),
        );

    return pw.Container(
      width: size.mmWidth * mm,
      height: size.mmHeight * mm,
      padding: const pw.EdgeInsets.all(1.5 * mm),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (library != null && library.isNotEmpty) text(library, delta: -1),
          if (title.isNotEmpty) text(title, bold: true, delta: 1),
          if (author.isNotEmpty)
            pw.Text(
              author,
              maxLines: 1,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: base,
                color: PdfColors.grey700,
              ),
            ),
          pw.Spacer(),
          pw.SizedBox(
            height: size.mmHeight * mm * 0.28,
            child: pw.BarcodeWidget(
              data: barcode,
              barcode: pw.Barcode.code128(),
              drawText: false,
            ),
          ),
          pw.SizedBox(height: 1 * mm),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  barcode,
                  maxLines: 1,
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: base,
                    color: PdfColors.black,
                  ),
                ),
              ),
              if (shelf.isNotEmpty) text(shelf, bold: true),
            ],
          ),
        ],
      ),
    );
  }
}

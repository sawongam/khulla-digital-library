// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/domain/copy_repository.dart';
import 'package:khulla/features/catalog/label/data/label_sheet_printer.dart';
import 'package:khulla/features/catalog/label/domain/models/label_bulk_queue_result.dart';
import 'package:khulla/features/catalog/label/domain/models/label_queue_entry.dart';
import 'package:khulla/features/catalog/label/domain/models/label_size.dart';
import 'package:khulla/features/catalog/label/presentation/cubit/label_state.dart';
import 'package:khulla/features/catalog/title/domain/title_repository.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The label desk: scan a copy, queue its sticker, lay out the sheet.
///
/// Page-scoped `@injectable` cubit. Reads [CopyRepository] for barcode
/// lookup, [TitleRepository] for the author line, and
/// [LibrarySettingsRepository] for the library name on property labels.
/// No table of its own — the queue is local state, so [loadLabelDesk] is the
/// only read and everything else is synchronous state.
///
/// [queueBarcode] emits and rethrows so the scan field can toast; layout
/// toggles just emit.
@injectable
class LabelCubit extends Cubit<LabelState> {
  LabelCubit(this._copies, this._titles, this._settings, this._printer)
    : super(const LabelState());

  final CopyRepository _copies;
  final TitleRepository _titles;
  final LibrarySettingsRepository _settings;
  final LabelSheetPrinter _printer;

  /// Loads the library name for property labels. Failures emit into state.
  Future<void> loadLabelDesk() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final profile = await _settings.findProfile();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          libraryName: profile?.name,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Queues the copy with [barcode], or bumps its count when it is already
  /// queued — a second scan of the same book means a second sticker, not a
  /// duplicate row. Emits and rethrows on failure so the scan field toasts.
  Future<void> queueBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    try {
      await _queueOne(trimmed);
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Queues every barcode in [barcodes] — one per pasted line, for a stack of
  /// copies that arrived with a printed accession list instead of a scanner
  /// at hand. A barcode matching nothing is skipped and reported back rather
  /// than aborting the rest, since one typo shouldn't cost the whole batch.
  ///
  /// A genuine data-layer failure still emits and rethrows, same as a single
  /// scan — the difference is that "no copy matches" is expected here, not
  /// exceptional.
  Future<LabelBulkQueueResult> queueBarcodes(List<String> barcodes) async {
    final notFound = <String>[];
    var queuedCount = 0;
    final seen = <String>{};

    try {
      for (final raw in barcodes) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty || !seen.add(trimmed)) continue;
        try {
          await _queueOne(trimmed);
          if (isClosed) {
            return LabelBulkQueueResult(
              queuedCount: queuedCount,
              notFound: notFound,
            );
          }
          queuedCount++;
        } on NotFoundException {
          notFound.add(trimmed);
        }
      }
    } on AppException catch (error) {
      if (isClosed) {
        return LabelBulkQueueResult(
          queuedCount: queuedCount,
          notFound: notFound,
        );
      }
      emit(state.copyWith(error: error));
      rethrow;
    }
    return LabelBulkQueueResult(queuedCount: queuedCount, notFound: notFound);
  }

  /// Looks up [barcode] and queues it, bumping the count when it is already
  /// queued. Throws [NotFoundException] when nothing matches.
  Future<void> _queueOne(String barcode) async {
    final copy = await _copies.findCopyByBarcode(barcode);
    if (isClosed) return;
    if (copy == null) {
      throw const NotFoundException('No copy matches that barcode.');
    }
    final title = await _titles.findTitle(copy.titleId);
    if (isClosed) return;
    final index = state.queue.indexWhere((entry) => entry.copy.id == copy.id);
    if (index == -1) {
      emit(
        state.copyWith(
          queue: [
            ...state.queue,
            LabelQueueEntry(copy: copy, author: title?.author),
          ],
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          queue: [
            for (final (position, entry) in state.queue.indexed)
              if (position == index)
                entry.withCount(entry.count + 1)
              else
                entry,
          ],
          error: null,
        ),
      );
    }
  }

  void setEntryCount(LabelQueueEntry entry, int count) {
    emit(
      state.copyWith(
        queue: [
          for (final queued in state.queue)
            if (queued.copy.id == entry.copy.id)
              queued.withCount(count)
            else
              queued,
        ],
        error: null,
      ),
    );
  }

  void removeEntry(LabelQueueEntry entry) {
    emit(
      state.copyWith(
        queue: [
          for (final queued in state.queue)
            if (queued.copy.id != entry.copy.id) queued,
        ],
        error: null,
      ),
    );
  }

  void clearQueue() {
    emit(state.copyWith(queue: const [], error: null));
  }

  void sizeChanged(LabelSize size) {
    emit(state.copyWith(size: size));
  }

  void includeTitleChanged(bool value) {
    emit(state.copyWith(includeTitle: value));
  }

  void includeAuthorChanged(bool value) {
    emit(state.copyWith(includeAuthor: value));
  }

  void includeShelfChanged(bool value) {
    emit(state.copyWith(includeShelf: value));
  }

  void includeLibraryChanged(bool value) {
    emit(state.copyWith(includeLibrary: value));
  }

  /// Builds the sheet PDF and opens the OS print dialog.
  ///
  /// Returns whether the sheet reached the dialog — a dismissed dialog
  /// answers `false` and stays silent. Emits and rethrows on failure so the
  /// print button can toast.
  Future<bool> printSheet() async {
    if (state.isPrinting || state.queue.isEmpty) return false;
    emit(state.copyWith(isPrinting: true, error: null));
    try {
      final printed = await _printer.printSheet(
        queue: state.queue,
        size: state.size,
        includeTitle: state.includeTitle,
        includeAuthor: state.includeAuthor,
        includeShelf: state.includeShelf,
        libraryName: state.includeLibrary ? state.libraryName : null,
      );
      if (isClosed) return false;
      emit(state.copyWith(isPrinting: false, error: null));
      return printed;
    } on AppException catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(isPrinting: false, error: error));
      rethrow;
    }
  }
}

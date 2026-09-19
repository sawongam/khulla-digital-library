// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/catalog/label/presentation/cubit/label_cubit.dart';
import 'package:khulla/features/catalog/label/presentation/cubit/label_state.dart';
import 'package:khulla/features/catalog/label/presentation/widgets/label_bulk_queue_dialog.dart';
import 'package:khulla/features/catalog/label/presentation/widgets/label_layout_cards.dart';
import 'package:khulla/features/catalog/label/presentation/widgets/label_queue_cards.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The label desk: scan a copy, queue its sticker, print the sheet.
///
/// The scan field keeps focus and clears itself on submit, because a handheld
/// scanner is a keyboard that types a barcode and presses enter — anything
/// that steals focus between two scans turns a tray of new books into a
/// hunt-and-click job.
///
/// [LabelCubit] owns the queue and the layout; a scan that matches nothing
/// answers as a toast, not as a screen state. The cards live in
/// `presentation/widgets/`; this page owns focus and the print toasts.
class LabelPrintPage extends StatefulWidget {
  const LabelPrintPage({super.key});

  @override
  State<LabelPrintPage> createState() => _LabelPrintPageState();
}

class _LabelPrintPageState extends State<LabelPrintPage> with DisposeBag {
  late final TextEditingController _scanController = textController();
  late final FocusNode _scanFocus = focusNode();

  Future<void> _queueBarcode(String raw) async {
    final cubit = context.read<LabelCubit>();
    final l10n = context.l10n;
    try {
      await cubit.queueBarcode(raw);
      if (!mounted) return;
      _scanController.clear();
      _scanFocus.requestFocus();
    } on AppException catch (error) {
      if (!mounted) return;
      _scanController.clear();
      _scanFocus.requestFocus();
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _printSheet() async {
    final cubit = context.read<LabelCubit>();
    final l10n = context.l10n;
    final count = cubit.state.labelCount;
    try {
      final printed = await cubit.printSheet();
      if (!mounted || !printed) return;
      AppToast.success(
        context,
        message: l10n.labelsPrintSuccess('$count'),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _bulkQueue() async {
    final l10n = context.l10n;
    final result = await LabelBulkQueueDialog.show(context);
    if (result == null || !mounted) return;
    _scanFocus.requestFocus();
    if (result.isComplete) {
      if (result.queuedCount == 0) return;
      AppToast.success(
        context,
        message: l10n.labelsBulkAllQueued('${result.queuedCount}'),
      );
    } else {
      AppToast.warning(
        context,
        message: l10n.labelsBulkPartial(
          '${result.queuedCount}',
          '${result.notFound.length}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final cubit = context.read<LabelCubit>();
    final sideBySide = context.formFactor.isAtLeast(FormFactor.expanded);

    return BlocBuilder<LabelCubit, LabelState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadLabelDesk,
          );
        }

        final main = [
          LabelScanCard(
            scanController: _scanController,
            scanFocus: _scanFocus,
            onSubmitted: (value) => unawaited(_queueBarcode(value)),
            onBulkQueue: () => unawaited(_bulkQueue()),
          ),
          LabelQueueCard(
            queue: state.queue,
            labelCount: state.labelCount,
            onClearQueue: cubit.clearQueue,
            onCountChanged: cubit.setEntryCount,
            onRemove: cubit.removeEntry,
          ),
        ];
        final side = [
          LabelLayoutCard(
            size: state.size,
            includeTitle: state.includeTitle,
            includeAuthor: state.includeAuthor,
            includeShelf: state.includeShelf,
            includeLibrary: state.includeLibrary,
            onSizeChanged: cubit.sizeChanged,
            onIncludeTitleChanged: cubit.includeTitleChanged,
            onIncludeAuthorChanged: cubit.includeAuthorChanged,
            onIncludeShelfChanged: cubit.includeShelfChanged,
            onIncludeLibraryChanged: cubit.includeLibraryChanged,
          ),
          LabelPreviewCard(
            queue: state.queue,
            size: state.size,
            includeTitle: state.includeTitle,
            includeAuthor: state.includeAuthor,
            includeShelf: state.includeShelf,
            includeLibrary: state.includeLibrary,
            libraryName: state.libraryName,
            isPrinting: state.isPrinting,
            onPrint: () => unawaited(_printSheet()),
          ),
        ];

        return AppPageBody(
          wide: true,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  spacing.page,
                  spacing.lg,
                  spacing.page,
                  spacing.xlg,
                ),
                sliver: SliverList.list(
                  children: [
                    Text(
                      l10n.labelsSubtitle,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    if (sideBySide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _CardStack(gap: spacing.md, children: main),
                          ),
                          SizedBox(width: spacing.md),
                          SizedBox(
                            width: 360,
                            child: _CardStack(gap: spacing.md, children: side),
                          ),
                        ],
                      )
                    else
                      _CardStack(gap: spacing.md, children: [...main, ...side]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A column of cards with one gap between them.
class _CardStack extends StatelessWidget {
  const _CardStack({required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, child) in children.indexed) ...[
        if (index > 0) SizedBox(height: gap),
        child,
      ],
    ],
  );
}

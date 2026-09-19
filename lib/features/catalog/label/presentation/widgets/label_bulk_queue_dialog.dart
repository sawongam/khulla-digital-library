// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/catalog/label/domain/models/label_bulk_queue_result.dart';
import 'package:khulla/features/catalog/label/presentation/cubit/label_cubit.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A pasted list of barcodes, queued in one go.
///
/// For a stack of copies that arrived with a printed accession list rather
/// than a handheld scanner — typing or scanning one at a time is the wrong
/// tool when there are fifty of them. Resolves to a [LabelBulkQueueResult] so
/// the scan card can toast how many matched; null if cancelled.
class LabelBulkQueueDialog extends StatefulWidget {
  const LabelBulkQueueDialog({super.key});

  /// Shows the dialog over [context].
  ///
  /// `showDialog` mounts into the root navigator's overlay, above the
  /// page-scoped [LabelCubit] — so the instance is read here, where it *is*
  /// in scope, and re-provided into the dialog's subtree.
  static Future<LabelBulkQueueResult?> show(BuildContext context) {
    final cubit = context.read<LabelCubit>();
    return showDialog<LabelBulkQueueResult>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const LabelBulkQueueDialog(),
      ),
    );
  }

  @override
  State<LabelBulkQueueDialog> createState() => _LabelBulkQueueDialogState();
}

class _LabelBulkQueueDialogState extends State<LabelBulkQueueDialog>
    with DisposeBag {
  late final TextEditingController _controller = textController();
  bool _isQueueing = false;
  AppException? _error;

  Future<void> _queue() async {
    final lines = _controller.text.split('\n');
    if (lines.every((line) => line.trim().isEmpty)) return;

    final cubit = context.read<LabelCubit>();
    setState(() {
      _isQueueing = true;
      _error = null;
    });
    try {
      final result = await cubit.queueBarcodes(lines);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _isQueueing = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppDialog(
      title: l10n.labelsBulkTitle,
      message: l10n.labelsBulkSubtitle,
      width: AppDialogWidth.xxxl,
      showClose: !_isQueueing,
      content: AppTextField(
        controller: _controller,
        autofocus: true,
        enabled: !_isQueueing,
        hintText: l10n.labelsBulkHint,
        errorText: _error?.localizedMessage(l10n),
        minLines: 6,
        maxLines: 10,
        onChanged: (_) {},
      ),
      actions: AppDialogActions(
        children: [
          AppDialog.secondaryAction(
            context: context,
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppDialog.primaryAction(
            context: context,
            label: l10n.labelsBulkQueueAction,
            isLoading: _isQueueing,
            onPressed: _queue,
          ),
        ],
      ),
    );
  }
}

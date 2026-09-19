// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title_format/title_format_cubit.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title_format/title_format_state.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/presentation/cubit/reference_data_cubit.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Lists catalogue formats and lets staff create, rename or hide them.
abstract final class TitleFormatListDialog {
  static Future<void> show(BuildContext context) {
    final l10n = context.l10n;
    final cubit = getIt<TitleFormatCubit>();
    unawaited(cubit.loadFormats());
    return AppSideSheet.show<void>(
      context: context,
      title: l10n.titlesManageFormats,
      caption: l10n.titlesManageFormatsBody,
      closeTooltip: l10n.commonClose,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _TitleFormatSheetBody(),
      ),
      actionsBuilder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: const _TitleFormatSheetActions(),
      ),
    ).whenComplete(cubit.close);
  }
}

class _TitleFormatSheetBody extends StatelessWidget {
  const _TitleFormatSheetBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TitleFormatCubit, TitleFormatState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: context.read<TitleFormatCubit>().loadFormats,
          );
        }
        return _TitleFormatList(formats: state.formats);
      },
    );
  }
}

class _TitleFormatSheetActions extends StatelessWidget {
  const _TitleFormatSheetActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialogActions(
      children: [
        AppDialog.primaryAction(
          context: context,
          label: l10n.titleFormAddFormat,
          onPressed: () => unawaited(_addFormat(context)),
        ),
      ],
    );
  }
}

class _TitleFormatList extends StatelessWidget {
  const _TitleFormatList({required this.formats});

  final List<TitleFormat> formats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final canDelete = formats.length > 1;

    if (formats.isEmpty) {
      return AppEmptyView(
        variant: AppFeedbackVariant.inline,
        title: l10n.titlesFormatsEmptyTitle,
        message: l10n.titlesFormatsEmptyBody,
        actionLabel: l10n.titleFormAddFormat,
        onAction: () => unawaited(_addFormat(context)),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: AppTable<TitleFormat>(
        items: formats,
        columns: [
          AppTableColumn<TitleFormat>(
            id: 'name',
            label: l10n.fieldFormat,
            flex: 4,
            cellBuilder: (context, format) => Row(
              children: [
                AppIcon(
                  format.icon,
                  size: context.appSpacing.md,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(width: context.appSpacing.xs),
                Expanded(
                  child: Text(
                    format.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          AppTableColumn<TitleFormat>(
            id: 'actions',
            label: l10n.commonActions,
            width: 104,
            alignment: Alignment.centerRight,
            cellBuilder: (context, format) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  icon: AppIcons.edit,
                  tooltip: l10n.commonEdit,
                  size: AppIconButtonSize.small,
                  onPressed: () => unawaited(_saveFormat(context, format)),
                ),
                AppIconButton(
                  icon: AppIcons.delete,
                  tooltip: l10n.commonDelete,
                  size: AppIconButtonSize.small,
                  tone: AppStatusTone.danger,
                  onPressed: canDelete
                      ? () => unawaited(_removeFormat(context, format))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _refreshPickers(BuildContext context) {
  return context.read<ReferenceDataCubit>().refreshFormats();
}

Future<String?> _askFormatName(
  BuildContext context, {
  required String heading,
  required String confirmLabel,
  String? initial,
}) {
  return AppFormModal.show<String>(
    context: context,
    builder: (_) => _FormatNameDialog(
      heading: heading,
      confirmLabel: confirmLabel,
      initial: initial,
    ),
  );
}

Future<void> _addFormat(BuildContext context) async {
  final l10n = context.l10n;
  final name = await _askFormatName(
    context,
    heading: l10n.titleFormCreateFormatHeading,
    confirmLabel: l10n.titleFormAddFormat,
  );
  if (name == null || name.isEmpty || !context.mounted) return;
  try {
    await context.read<TitleFormatCubit>().addFormat(name);
    if (!context.mounted) return;
    await _refreshPickers(context);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

Future<void> _saveFormat(BuildContext context, TitleFormat format) async {
  final l10n = context.l10n;
  final name = await _askFormatName(
    context,
    heading: l10n.titlesFormatEditHeading,
    confirmLabel: l10n.commonSave,
    initial: format.name,
  );
  if (name == null || name.isEmpty || !context.mounted) return;
  try {
    await context.read<TitleFormatCubit>().saveFormat(
      id: format.id,
      name: name,
    );
    if (!context.mounted) return;
    await _refreshPickers(context);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

Future<void> _removeFormat(BuildContext context, TitleFormat format) async {
  final l10n = context.l10n;
  final formats = context.read<TitleFormatCubit>().state.formats;
  if (formats.length <= 1) {
    AppToast.error(context, message: l10n.titlesFormatLastBody);
    return;
  }
  final confirmed = await AppDialog.confirmDestructive(
    context: context,
    title: l10n.titlesFormatDeleteTitle,
    message: l10n.titlesFormatDeleteBody,
    confirmLabel: l10n.commonDelete,
    cancelLabel: l10n.commonCancel,
  );
  if (!context.mounted || !confirmed) return;
  try {
    await context.read<TitleFormatCubit>().removeFormat(format.id);
    if (!context.mounted) return;
    await _refreshPickers(context);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

class _FormatNameDialog extends StatefulWidget {
  const _FormatNameDialog({
    required this.heading,
    required this.confirmLabel,
    this.initial,
  });

  final String heading;
  final String confirmLabel;
  final String? initial;

  @override
  State<_FormatNameDialog> createState() => _FormatNameDialogState();
}

class _FormatNameDialogState extends State<_FormatNameDialog> with DisposeBag {
  late final TextEditingController _name = textController(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: widget.heading,
      width: AppDialogWidth.sm,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: widget.confirmLabel,
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              AppToast.error(context, message: l10n.validationFieldRequired);
              return;
            }
            Navigator.of(context).pop(name);
          },
        ),
      ],
      children: [
        AppTextField(
          label: l10n.fieldFormat,
          required: true,
          controller: _name,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

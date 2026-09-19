// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_form_cubit.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_form_state.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Adds one physical copy to an existing title.
class CopyFormDialog extends StatelessWidget {
  const CopyFormDialog({this.titleId, super.key});

  final String? titleId;

  static Future<bool?> show(BuildContext context, {String? titleId}) =>
      AppFormModal.show<bool>(
        context: context,
        builder: (_) => BlocProvider(
          create: (_) {
            final cubit = getIt<CopyFormCubit>();
            unawaited(cubit.load(titleId: titleId));
            return cubit;
          },
          child: CopyFormDialog(titleId: titleId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CopyFormCubit, CopyFormState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppFormModal(
            title: l10n.copyFormHeading,
            width: AppDialogWidth.xxxl,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }

        return _CopyFormBody(
          key: ValueKey(titleId ?? 'pick'),
          state: state,
        );
      },
    );
  }
}

class _CopyFormBody extends StatefulWidget {
  const _CopyFormBody({required this.state, super.key});

  final CopyFormState state;

  @override
  State<_CopyFormBody> createState() => _CopyFormBodyState();
}

class _CopyFormBodyState extends State<_CopyFormBody> with DisposeBag {
  late final TextEditingController _shelf = textController(
    widget.state.fixedTitle?.shelf,
  );
  late final TextEditingController _barcode = textController();
  late final TextEditingController _notes = textController();

  Future<void> _save() async {
    final l10n = context.l10n;
    try {
      await context.read<CopyFormCubit>().saveCopy(
        shelf: _shelf.text,
        barcode: _barcode.text,
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final state = widget.state;
    final fixed = state.fixedTitle;
    final selected = state.selectedTitle;

    return AppFormModal(
      title: l10n.copyFormHeading,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.copyFormSave,
          isLoading: state.isSaving,
          onPressed: () => unawaited(_save()),
        ),
      ],
      children: [
        AppFormSection(
          title: l10n.copyFormTitleSection,
          description: l10n.copyFormTitleDescription,
          children: [
            if (fixed != null)
              AppDetailRow(
                label: l10n.titlesColumnTitle,
                child: Text(fixed.title),
              )
            else ...[
              AppSearchField(
                hintText: l10n.titlesSearchHint,
                clearTooltip: l10n.commonClearSearch,
                onChanged: context.read<CopyFormCubit>().titleSearchChanged,
              ),
              if (selected != null) ...[
                SizedBox(height: spacing.sm),
                AppDetailRow(
                  label: l10n.titlesColumnTitle,
                  child: Text(selected.title),
                ),
              ],
              if (state.titleMatches.isNotEmpty) ...[
                SizedBox(height: spacing.sm),
                for (final title in state.titleMatches)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.xxs),
                    child: _TitlePickRow(
                      title: title,
                      selected: selected?.id == title.id,
                      onTap: () =>
                          context.read<CopyFormCubit>().titleSelected(title),
                    ),
                  ),
              ],
            ],
          ],
        ),
        AppFormSection(
          title: l10n.copyFormDetailsSection,
          children: [
            AppFormRow(
              children: [
                AppTextField(
                  label: l10n.fieldShelf,
                  controller: _shelf,
                  onChanged: (_) {},
                ),
                AppTextField(
                  label: l10n.fieldBarcode,
                  controller: _barcode,
                  hintText: l10n.copyFormBarcodeHint,
                  onChanged: (_) {},
                ),
              ],
            ),
            AppTextField(
              label: l10n.fieldNotes,
              controller: _notes,
              maxLines: 3,
              minLines: 2,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

class _TitlePickRow extends StatelessWidget {
  const _TitlePickRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final catalog.Title title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  title.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            AppIcon(AppIcons.success, color: scheme.primary, size: 18),
        ],
      ),
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_detail_cubit.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_detail_state.dart';
import 'package:khulla/features/catalog/title/presentation/title_form_dialog.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_copies_card.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_detail_header.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_details_card.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_history_card.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One work's record: what it is, the copies under it, and who has had them.
///
/// Two panes from [FormFactor.expanded] up — copies and loan history on the left, where the tables need the width, and the
/// bibliographic record on the right — and one column below that, in the same
/// order: copies and history before publication details, since checking a
/// copy's status is why a librarian opens this page more often than checking
/// its edition. The page keeps the shell's rail rather than pushing a screen
/// over it, because a librarian moving between records is still inside the
/// catalogue.
///
/// [TitleDetailCubit] loads the title, its copies and closed loans for
/// [TitleHistoryCard]. Edit, delete, add-copy and copy maintenance are wired;
/// print labels still toast as not wired.
class TitleDetailPage extends StatelessWidget {
  const TitleDetailPage({required this.titleId, super.key});

  final String titleId;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.titleDetailDeleteTitle,
      message: l10n.titleDetailDeleteBody,
      confirmLabel: l10n.titleDetailDelete,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await context.read<TitleDetailCubit>().removeTitle(titleId);
      if (!context.mounted) return;
      context.go(Routes.catalogTitles);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<int?> _promptAddCopyCount(BuildContext context) {
    return AppFormModal.show<int>(
      context: context,
      builder: (_) => const _AddCopyCountDialog(),
    );
  }

  Future<void> _addCopy(BuildContext context, TitleDetailState state) async {
    final title = state.title;
    if (title == null) return;
    final l10n = context.l10n;
    final count = await _promptAddCopyCount(context);
    if (!context.mounted || count == null) return;
    try {
      await context.read<TitleDetailCubit>().addCopies(
        titleId,
        title.title,
        count: count,
        shelf: title.shelf,
      );
      if (!context.mounted) return;
      AppToast.success(
        context,
        message: l10n.titleDetailAddCopySuccess(count),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await TitleFormDialog.show(context, titleId: titleId);
    if (saved == true && context.mounted) {
      unawaited(context.read<TitleDetailCubit>().loadTitle(titleId));
    }
  }

  Future<void> _runCopyAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    final l10n = context.l10n;
    try {
      await action();
      if (!context.mounted) return;
      AppToast.success(context, message: successMessage);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _markCopyLost(BuildContext context, Copy copy) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.copiesMarkLost,
      message: l10n.copiesMarkLostBody,
      confirmLabel: l10n.copiesMarkLost,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    await _runCopyAction(
      context,
      () => context.read<TitleDetailCubit>().markCopyLost(titleId, copy),
      l10n.copiesMarkLostSuccess,
    );
  }

  Future<void> _markCopyDamaged(BuildContext context, Copy copy) async {
    final l10n = context.l10n;
    await _runCopyAction(
      context,
      () => context.read<TitleDetailCubit>().markCopyDamaged(titleId, copy),
      l10n.copiesMarkDamagedSuccess,
    );
  }

  Future<void> _withdrawCopy(BuildContext context, Copy copy) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.copiesWithdraw,
      message: l10n.copiesWithdrawBody,
      confirmLabel: l10n.copiesWithdraw,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    await _runCopyAction(
      context,
      () => context.read<TitleDetailCubit>().withdrawCopy(titleId, copy),
      l10n.copiesWithdrawSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return BlocBuilder<TitleDetailCubit, TitleDetailState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: () => context.read<TitleDetailCubit>().loadTitle(titleId),
          );
        }
        final title = state.title;
        if (title == null) {
          return Center(child: Text(l10n.commonNotSet));
        }

        final twoPane = context.formFactor.isAtLeast(FormFactor.expanded);
        final description = title.description;

        // A record is readable by anyone who can open the catalogue; changing
        // it is a separate permission, so every control that writes — the
        // header's edit and delete, and each copy's maintenance menu — is
        // absent rather than disabled for a role that only reads.
        final canManage = context.canManage(StaffPermission.catalog);

        final copiesCard = TitleCopiesCard(
          copies: state.copies,
          onAddCopy: !canManage
              ? null
              : () => unawaited(_addCopy(context, state)),
          onMarkLost: !canManage
              ? null
              : (copy) => unawaited(_markCopyLost(context, copy)),
          onMarkDamaged: !canManage
              ? null
              : (copy) => unawaited(_markCopyDamaged(context, copy)),
          onWithdraw: !canManage
              ? null
              : (copy) => unawaited(_withdrawCopy(context, copy)),
        );
        final historyCard = TitleHistoryCard(loans: state.historyLoans);
        final detailsCard = TitleDetailsCard(title: title);
        final descriptionCard = description == null
            ? null
            : SectionCard(
                title: l10n.titleDetailDescription,
                child: Text(
                  description,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              );

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
                    TitleDetailHeader(
                      title: title,
                      onEdit: !canManage
                          ? null
                          : () => unawaited(_edit(context)),
                      onDelete: !canManage
                          ? null
                          : () => unawaited(_confirmDelete(context)),
                    ),
                    SizedBox(height: spacing.md),
                    if (twoPane)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                copiesCard,
                                SizedBox(height: spacing.md),
                                historyCard,
                              ],
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                detailsCard,
                                if (descriptionCard != null) ...[
                                  SizedBox(height: spacing.md),
                                  descriptionCard,
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      copiesCard,
                      SizedBox(height: spacing.md),
                      historyCard,
                      SizedBox(height: spacing.md),
                      detailsCard,
                      if (descriptionCard != null) ...[
                        SizedBox(height: spacing.md),
                        descriptionCard,
                      ],
                    ],
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

class _AddCopyCountDialog extends StatefulWidget {
  const _AddCopyCountDialog();

  @override
  State<_AddCopyCountDialog> createState() => _AddCopyCountDialogState();
}

class _AddCopyCountDialogState extends State<_AddCopyCountDialog>
    with DisposeBag {
  late final TextEditingController _controller = textController('1');
  String? _errorText;

  void _submit() {
    final count = int.tryParse(_controller.text);
    if (count == null || count < 1) {
      setState(() => _errorText = context.l10n.validationCopiesMin);
      return;
    }
    Navigator.of(context).pop(count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: l10n.titleDetailAddCopyDialogTitle,
      width: AppDialogWidth.sm,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.commonAdd,
          onPressed: _submit,
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFieldLabel(
              label: l10n.titleDetailAddCopyCount,
              required: true,
              hasError: _errorText != null,
            ),
            SizedBox(height: context.appMetrics.labelToControlGap),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.3,
                child: AppQuantityField(
                  size: AppQuantityFieldSize.small,
                  controller: _controller,
                  decreaseTooltip: l10n.commonDecrease,
                  increaseTooltip: l10n.commonIncrease,
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
              ),
            ),
            if (_errorText case final error?) ...[
              SizedBox(height: context.appSpacing.xxs + 2),
              AppFieldError(message: error),
            ],
          ],
        ),
      ],
    );
  }
}

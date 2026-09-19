// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/cubit/member_type_cubit.dart';
import 'package:khulla/features/members/presentation/widgets/member_type_form_dialog.dart';
import 'package:khulla/features/members/presentation/widgets/member_type_sheet.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Lists member categories and lets staff create, edit, archive or restore
/// them - including the loan-rule overrides each one carries.
///
/// Orchestration only: the sheet body, rows and form live in
/// `presentation/widgets/`; every write below emits into the cubit and
/// toasts at this call site.
abstract final class MemberTypeListDialog {
  static Future<void> show(BuildContext context) {
    final l10n = context.l10n;
    final cubit = getIt<MemberTypeCubit>();
    unawaited(cubit.loadTypes());
    return AppSideSheet.show<void>(
      context: context,
      title: l10n.membersManageCategories,
      caption: l10n.membersManageCategoriesBody,
      closeTooltip: l10n.commonClose,
      width: 560,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: MemberTypeSheetBody(
          onAdd: () => unawaited(_addType(context)),
          onEdit: (type) => unawaited(_saveType(context, type)),
          onArchive: (type) => unawaited(_archiveType(context, type)),
          onRestore: (type) => unawaited(_restoreType(context, type)),
        ),
      ),
      actionsBuilder: (_) => BlocProvider.value(
        value: cubit,
        child: MemberTypeSheetActions(
          onAdd: () => unawaited(_addType(context)),
        ),
      ),
    ).whenComplete(cubit.close);
  }
}

Future<void> _addType(BuildContext context) async {
  final l10n = context.l10n;
  final draft = await MemberTypeFormDialog.show(
    context,
    heading: l10n.memberTypeCreateHeading,
    confirmLabel: l10n.memberTypeAddCategory,
  );
  if (draft == null || !context.mounted) return;
  try {
    await context.read<MemberTypeCubit>().addType(draft);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

Future<void> _saveType(BuildContext context, MemberType type) async {
  final l10n = context.l10n;
  final draft = await MemberTypeFormDialog.show(
    context,
    heading: l10n.memberTypeEditHeading,
    confirmLabel: l10n.commonSave,
    existing: type,
  );
  if (draft == null || !context.mounted) return;
  try {
    await context.read<MemberTypeCubit>().saveType(draft);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

Future<void> _archiveType(BuildContext context, MemberType type) async {
  final l10n = context.l10n;
  final confirmed = await AppDialog.confirmDestructive(
    context: context,
    title: l10n.memberTypeArchiveTitle,
    message: l10n.memberTypeArchiveBody,
    confirmLabel: l10n.commonArchive,
    cancelLabel: l10n.commonCancel,
  );
  if (!context.mounted || !confirmed) return;
  try {
    await context.read<MemberTypeCubit>().archiveType(type.id);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

Future<void> _restoreType(BuildContext context, MemberType type) async {
  final l10n = context.l10n;
  try {
    await context.read<MemberTypeCubit>().unarchiveType(type.id);
  } on AppException catch (error) {
    if (!context.mounted) return;
    AppToast.error(context, message: error.localizedMessage(l10n));
  }
}

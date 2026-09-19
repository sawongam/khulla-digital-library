// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/cubit/member_type_cubit.dart';
import 'package:khulla/features/members/presentation/cubit/member_type_state.dart';
import 'package:khulla/features/members/presentation/widgets/member_type_list.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The sheet body behind the category dialog: loading, error and the
/// [MemberTypeList], with row taps fanning out to the dialog's handlers.
class MemberTypeSheetBody extends StatelessWidget {
  const MemberTypeSheetBody({
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    super.key,
  });

  final VoidCallback onAdd;
  final void Function(MemberType type) onEdit;
  final void Function(MemberType type) onArchive;
  final void Function(MemberType type) onRestore;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemberTypeCubit, MemberTypeState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: context.read<MemberTypeCubit>().loadTypes,
          );
        }
        return MemberTypeList(
          types: state.types,
          onAdd: onAdd,
          onEdit: onEdit,
          onArchive: onArchive,
          onRestore: onRestore,
        );
      },
    );
  }
}

/// The sheet footer behind the category dialog: the single add-category
/// action.
class MemberTypeSheetActions extends StatelessWidget {
  const MemberTypeSheetActions({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialogActions(
      children: [
        AppDialog.primaryAction(
          context: context,
          label: l10n.memberTypeAddCategory,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

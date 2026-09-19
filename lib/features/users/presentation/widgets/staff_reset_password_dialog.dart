// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_password_field.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_state.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Sets a new password for an existing account.
///
/// There is no invitation link to resend and no reset email to send in an
/// offline-first app — an administrator chooses the new password here and
/// hands it to the account holder directly, the same way the very first
/// administrator's password is chosen at onboarding.
class StaffResetPasswordDialog extends StatelessWidget {
  const StaffResetPasswordDialog({
    required this.staffId,
    required this.staffName,
    super.key,
  });

  final String staffId;
  final String staffName;

  static Future<bool?> show(
    BuildContext context, {
    required String staffId,
    required String staffName,
  }) => AppFormModal.show<bool>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = getIt<StaffFormCubit>();
        unawaited(
          cubit.load(mode: StaffFormMode.resetPassword, staffId: staffId),
        );
        return cubit;
      },
      child: StaffResetPasswordDialog(staffId: staffId, staffName: staffName),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffFormCubit, StaffFormState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state.isLoading) {
          return AppFormModal(
            title: l10n.usersResetPasswordHeading,
            width: AppDialogWidth.lg,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }
        if (state.status.hasError) {
          return AppFormModal(
            title: l10n.usersResetPasswordHeading,
            width: AppDialogWidth.lg,
            actions: [
              AppDialog.secondaryAction(
                context: context,
                label: l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            children: [
              Text(state.error?.localizedMessage(l10n) ?? ''),
            ],
          );
        }
        return _ResetPasswordBody(staffName: staffName);
      },
    );
  }
}

class _ResetPasswordBody extends StatefulWidget {
  const _ResetPasswordBody({required this.staffName});

  final String staffName;

  @override
  State<_ResetPasswordBody> createState() => _ResetPasswordBodyState();
}

class _ResetPasswordBodyState extends State<_ResetPasswordBody>
    with DisposeBag {
  late final TextEditingController _password = textController();
  late final TextEditingController _confirmPassword = textController();

  Future<void> _submit() async {
    final l10n = context.l10n;
    final cubit = context.read<StaffFormCubit>();
    try {
      final ok = await cubit.resetPassword();
      if (!mounted || !ok) return;
      AppToast.success(context, message: l10n.usersResetPasswordToast);
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<StaffFormCubit>().state;
    final cubit = context.read<StaffFormCubit>();

    return AppFormModal(
      title: l10n.usersResetPasswordHeading,
      description: l10n.usersResetPasswordDescription(widget.staffName),
      width: AppDialogWidth.lg,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.usersResetPassword,
          isLoading: state.isSubmitting,
          onPressed: () => unawaited(_submit()),
        ),
      ],
      children: [
        AppFormRow(
          children: [
            AuthPasswordField(
              label: l10n.fieldPassword,
              controller: _password,
              autofocus: true,
              errorText: state.password.messageFor(l10n),
              onChanged: cubit.passwordChanged,
            ),
            AuthPasswordField(
              label: l10n.fieldConfirmPassword,
              controller: _confirmPassword,
              errorText: state.confirmPassword.messageFor(l10n),
              onChanged: cubit.confirmPasswordChanged,
            ),
          ],
        ),
      ],
    );
  }
}

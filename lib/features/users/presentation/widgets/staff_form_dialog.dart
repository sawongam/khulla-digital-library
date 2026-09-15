// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_password_field.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_state.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Add a staff account, or edit an existing one's name, email and role.
///
/// A modal, matching `MemberFormDialog` — the account list is the record,
/// there is no separate detail route to push. Password only appears when
/// adding: an existing account's password is changed from the row menu's
/// *Reset password* instead (see `StaffResetPasswordDialog`), which is its
/// own smaller form rather than an optional section here.
class StaffFormDialog extends StatelessWidget {
  const StaffFormDialog({this.staffId, super.key});

  final String? staffId;

  static Future<bool?> show(BuildContext context, {String? staffId}) =>
      AppFormModal.show<bool>(
        context: context,
        builder: (_) => BlocProvider(
          create: (_) {
            final cubit = getIt<StaffFormCubit>();
            unawaited(
              cubit.load(
                mode: staffId == null
                    ? StaffFormMode.create
                    : StaffFormMode.edit,
                staffId: staffId,
              ),
            );
            return cubit;
          },
          child: StaffFormDialog(staffId: staffId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = staffId != null;

    return BlocBuilder<StaffFormCubit, StaffFormState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppFormModal(
            title: isEditing ? l10n.usersEditHeading : l10n.usersAddHeading,
            width: AppDialogWidth.xxxl,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }
        if (state.status.hasError) {
          return AppFormModal(
            title: isEditing ? l10n.usersEditHeading : l10n.usersAddHeading,
            width: AppDialogWidth.xxxl,
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
        return _StaffFormBody(
          key: ValueKey(staffId ?? 'new'),
          staffId: staffId,
        );
      },
    );
  }
}

class _StaffFormBody extends StatefulWidget {
  const _StaffFormBody({required this.staffId, super.key});

  final String? staffId;

  @override
  State<_StaffFormBody> createState() => _StaffFormBodyState();
}

class _StaffFormBodyState extends State<_StaffFormBody> with DisposeBag {
  bool get _isEditing => widget.staffId != null;

  late final TextEditingController _name = textController(
    context.read<StaffFormCubit>().state.name.value,
  );
  late final TextEditingController _email = textController(
    context.read<StaffFormCubit>().state.email.value,
  );
  late final TextEditingController _password = textController();
  late final TextEditingController _confirmPassword = textController();

  Future<void> _save() async {
    final l10n = context.l10n;
    final cubit = context.read<StaffFormCubit>();
    try {
      final saved = await cubit.save();
      if (!mounted || saved == null) return;
      AppToast.success(
        context,
        message: _isEditing ? l10n.usersUpdatedToast : l10n.usersCreatedToast,
      );
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
      title: _isEditing ? l10n.usersEditHeading : l10n.usersAddHeading,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.commonSave,
          isLoading: state.isSubmitting,
          onPressed: () => unawaited(_save()),
        ),
      ],
      children: [
        AppTextField(
          label: l10n.fieldFullName,
          required: true,
          autofocus: true,
          controller: _name,
          textCapitalization: TextCapitalization.words,
          errorText: state.name.messageFor(l10n),
          onChanged: cubit.nameChanged,
        ),
        AppTextField(
          label: l10n.fieldEmail,
          required: true,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: state.emailTaken
              ? l10n.onboardingEmailTaken
              : state.email.messageFor(l10n),
          onChanged: cubit.emailChanged,
        ),
        AppDropdownField<UserRole>(
          label: l10n.fieldRole,
          required: true,
          value: state.role,
          items: UserRole.values,
          itemLabel: (role) => role.label(l10n),
          itemIcon: (role) => role.icon,
          onChanged: (role) => role == null ? null : cubit.roleChanged(role),
        ),
        AppPickerField(
          label: l10n.fieldBarcode,
          value: state.existing?.barcode ?? l10n.memberFormBarcodeHint,
          icon: AppIcons.scan,
          enabled: false,
          onTap: null,
        ),
        if (!_isEditing)
          AppFormRow(
            children: [
              AuthPasswordField(
                label: l10n.fieldPassword,
                controller: _password,
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

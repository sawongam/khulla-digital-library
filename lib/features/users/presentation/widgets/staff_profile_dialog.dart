// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_state.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/features/users/presentation/widgets/staff_reset_password_dialog.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Modal dialog displaying and managing the signed-in staff member's profile.
///
/// Opened from the account chip at the foot of the rail. Shows the account
/// identity, assigned role and permissions, and allows editing full name and
/// email as well as resetting password.
class StaffProfileDialog extends StatelessWidget {
  const StaffProfileDialog({super.key});

  /// Presents the profile dialog for the currently signed-in account.
  static Future<bool?> show(BuildContext context) {
    final staff = context.read<AuthCubit>().state.staff;
    if (staff == null) return Future.value();

    return AppFormModal.show<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) {
          final cubit = getIt<StaffFormCubit>();
          unawaited(
            cubit.load(
              mode: StaffFormMode.profile,
              staffId: staff.id,
            ),
          );
          return cubit;
        },
        child: const StaffProfileDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<StaffFormCubit, StaffFormState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppFormModal(
            title: l10n.shellProfile,
            width: AppDialogWidth.xxxl,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }
        if (state.status.hasError) {
          return AppFormModal(
            title: l10n.shellProfile,
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
        final staff = state.existing;
        if (staff == null) {
          return AppFormModal(
            title: l10n.shellProfile,
            width: AppDialogWidth.xxxl,
            actions: [
              AppDialog.secondaryAction(
                context: context,
                label: l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            children: const [],
          );
        }
        return _StaffProfileBody(staff: staff);
      },
    );
  }
}

class _StaffProfileBody extends StatefulWidget {
  const _StaffProfileBody({required this.staff});

  final StaffMember staff;

  @override
  State<_StaffProfileBody> createState() => _StaffProfileBodyState();
}

class _StaffProfileBodyState extends State<_StaffProfileBody> with DisposeBag {
  late final TextEditingController _name = textController(
    context.read<StaffFormCubit>().state.name.value,
  );
  late final TextEditingController _email = textController(
    context.read<StaffFormCubit>().state.email.value,
  );

  Future<void> _save() async {
    final l10n = context.l10n;
    final cubit = context.read<StaffFormCubit>();
    try {
      final saved = await cubit.save();
      if (!mounted || saved == null) return;
      AppToast.success(
        context,
        message: l10n.usersUpdatedToast,
      );
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _changePassword() async {
    await StaffResetPasswordDialog.show(
      context,
      staffId: widget.staff.id,
      staffName: widget.staff.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final state = context.watch<StaffFormCubit>().state;
    final cubit = context.read<StaffFormCubit>();
    final staff = widget.staff;

    return AppFormModal(
      title: l10n.shellProfile,
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
        Row(
          children: [
            AppAvatar(initials: staff.initials, size: 48),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          staff.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: colors.textHigh,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    staff.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDetailRow(
                label: l10n.fieldRole,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      staff.role.icon,
                      size: 16,
                      color: staff.role.tone.foreground(context),
                    ),
                    SizedBox(width: spacing.xxs),
                    Text(
                      staff.role.label(l10n),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: staff.role.tone.foreground(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                staff.role.description(l10n),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              SizedBox(height: spacing.sm),
              AppDetailRow.text(
                label: l10n.fieldJoined,
                value: AppDateFormat.format(staff.createdAt),
              ),
            ],
          ),
        ),
        AppTextField(
          label: l10n.fieldFullName,
          required: true,
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
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            onPressed: () => unawaited(_changePassword()),
            variant: AppButtonVariant.secondary,
            icon: AppIcons.resetPassword,
            child: Text(l10n.usersResetPassword),
          ),
        ),
      ],
    );
  }
}

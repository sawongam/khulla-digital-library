// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/staff_auth/presentation/recover_password/cubit/recover_password_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/recover_password/cubit/recover_password_state.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_error_notice.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_header.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_scaffold.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_secondary_action.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Sets a new administrator password using a one-time recovery code.
class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage>
    with DisposeBag {
  late final TextEditingController _email = textController();
  late final TextEditingController _recoveryCode = textController();
  late final TextEditingController _password = textController();
  late final TextEditingController _confirmPassword = textController();
  bool _passwordRevealed = false;
  bool _confirmPasswordRevealed = false;

  void _submit() =>
      context.read<RecoverPasswordCubit>().resetPasswordWithRecoveryCode();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return AuthScaffold(
      child: BlocBuilder<RecoverPasswordCubit, RecoverPasswordState>(
        builder: (context, state) {
          final cubit = context.read<RecoverPasswordCubit>();
          final error = state.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: l10n.recoverPasswordHeading,
                description: l10n.recoverPasswordSubtitle,
              ),
              SizedBox(height: spacing.lg),
              AppTextField(
                label: l10n.fieldEmail,
                hintText: l10n.signInEmailHint,
                required: true,
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: state.email.messageFor(l10n),
                onChanged: cubit.emailChanged,
              ),
              SizedBox(height: spacing.sm),
              AppTextField(
                label: l10n.recoverPasswordCodeLabel,
                hintText: l10n.recoverPasswordCodeHint,
                required: true,
                controller: _recoveryCode,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                errorText: state.recoveryCode.messageFor(l10n),
                onChanged: cubit.recoveryCodeChanged,
              ),
              SizedBox(height: spacing.sm),
              AppTextField(
                label: l10n.recoverPasswordNewPassword,
                hintText: l10n.signInPasswordHint,
                required: true,
                controller: _password,
                obscureText: !_passwordRevealed,
                textInputAction: TextInputAction.next,
                errorText: state.password.messageFor(l10n),
                onChanged: cubit.passwordChanged,
                suffixIcon: AppIconButton(
                  icon: _passwordRevealed
                      ? AppIcons.hidePassword
                      : AppIcons.revealPassword,
                  tooltip: _passwordRevealed
                      ? l10n.authHidePassword
                      : l10n.authRevealPassword,
                  size: AppIconButtonSize.small,
                  onPressed: () =>
                      setState(() => _passwordRevealed = !_passwordRevealed),
                ),
              ),
              SizedBox(height: spacing.sm),
              AppTextField(
                label: l10n.fieldConfirmPassword,
                hintText: l10n.authConfirmPasswordHint,
                required: true,
                controller: _confirmPassword,
                obscureText: !_confirmPasswordRevealed,
                textInputAction: TextInputAction.done,
                errorText: state.confirmPassword.messageFor(l10n),
                onChanged: cubit.confirmPasswordChanged,
                onSubmitted: (_) => _submit(),
                suffixIcon: AppIconButton(
                  icon: _confirmPasswordRevealed
                      ? AppIcons.hidePassword
                      : AppIcons.revealPassword,
                  tooltip: _confirmPasswordRevealed
                      ? l10n.authHidePassword
                      : l10n.authRevealPassword,
                  size: AppIconButtonSize.small,
                  onPressed: () => setState(
                    () => _confirmPasswordRevealed = !_confirmPasswordRevealed,
                  ),
                ),
              ),
              if (state.credentialsRejected) ...[
                SizedBox(height: spacing.md),
                AuthErrorNotice(message: l10n.recoverPasswordRejected),
              ],
              if (error != null) ...[
                SizedBox(height: spacing.md),
                AuthErrorNotice.exception(error),
              ],
              SizedBox(height: spacing.lg),
              AppButton(
                size: AppButtonSize.large,
                expand: true,
                isLoading: state.isSubmitting,
                onPressed: _submit,
                child: Text(l10n.recoverPasswordAction),
              ),
              SizedBox(height: spacing.lg),
              AuthSecondaryAction(
                label: l10n.recoverPasswordBackToSignIn,
                onTap: () => context.go(Routes.signIn),
              ),
            ],
          );
        },
      ),
    );
  }
}

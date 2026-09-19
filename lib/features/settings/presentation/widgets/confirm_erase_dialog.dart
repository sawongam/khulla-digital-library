// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The password gate in front of the erase.
///
/// One dialog does both jobs - stating the consequences and demanding the
/// operator's password - so there is no confirm-then-confirm stacking. A
/// wrong password stays on the field as a field error with retries; only a
/// verified password pops true, and the page erases behind it.
class ConfirmEraseDialog extends StatefulWidget {
  const ConfirmEraseDialog({super.key});

  /// True only when the operator proved who they are. False and null both
  /// mean the library stands.
  ///
  /// The cubit travels with the dialog via [BlocProvider.value]: the modal
  /// opens on the root navigator, above the settings route that provides
  /// the cubit, so the dialog's own context could never read it.
  static Future<bool> show(BuildContext context) async {
    final cubit = context.read<BackupCubit>();
    final confirmed = await AppFormModal.show<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const ConfirmEraseDialog(),
      ),
    );
    return confirmed ?? false;
  }

  @override
  State<ConfirmEraseDialog> createState() => _ConfirmEraseDialogState();
}

class _ConfirmEraseDialogState extends State<ConfirmEraseDialog>
    with DisposeBag {
  late final TextEditingController _password = textController();
  bool _wrongPassword = false;
  bool _verifying = false;

  Future<void> _submit() async {
    if (_verifying || _password.text.isEmpty) return;
    setState(() => _verifying = true);
    try {
      final verified = await context.read<BackupCubit>().verifyErasePassword(
        _password.text,
      );
      if (!mounted) return;
      if (verified) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _verifying = false;
        _wrongPassword = true;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _verifying = false);
      AppToast.error(
        context,
        message: error.localizedMessage(context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: l10n.settingsBackupEraseTitle,
      description: l10n.settingsBackupEraseBody,
      width: AppDialogWidth.sm,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialog.destructiveFilledAction(
          context: context,
          label: l10n.settingsBackupEraseAction,
          onPressed: () => unawaited(_submit()),
        ),
      ],
      children: [
        AppTextField(
          label: l10n.fieldPassword,
          controller: _password,
          autofocus: true,
          obscureText: true,
          textInputAction: TextInputAction.done,
          errorText: _wrongPassword
              ? l10n.settingsBackupEraseWrongPassword
              : null,
          onChanged: (_) {
            if (_wrongPassword) setState(() => _wrongPassword = false);
          },
          onSubmitted: (_) => unawaited(_submit()),
        ),
      ],
    );
  }
}

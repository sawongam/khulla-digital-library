// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/services.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/files/save_text_file.dart';
import 'package:khulla/core/security/recovery_code.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_state.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Step three: the one-time codes that reset the first administrator.
///
/// Shown before anything is written, so closing the window here does not
/// leave an account whose codes were never seen.
class OnboardingRecoveryStep extends StatelessWidget {
  const OnboardingRecoveryStep({
    required this.state,
    required this.onCodesSavedChanged,
    super.key,
  });

  final OnboardingState state;
  final ValueChanged<bool> onCodesSavedChanged;

  Future<void> _copyCodes(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: state.recoveryCodes.join('\n')),
    );
    if (!context.mounted) return;
    AppToast.success(context, message: context.l10n.onboardingCodesCopied);
  }

  Future<void> _downloadCodes(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final saved = await saveTextFile(
        filename: 'khulla-recovery-codes.txt',
        contents: RecoveryCode.fileContents(
          libraryName: state.libraryName.value,
          codes: state.recoveryCodes,
        ),
      );
      if (!context.mounted || saved == null) return;
      AppToast.success(
        context,
        message: l10n.onboardingCodesDownloaded,
        description: saved.path,
      );
    } on Object {
      if (!context.mounted) return;
      AppToast.error(context, message: l10n.onboardingCodesDownloadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;
    final codes = state.recoveryCodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          tone: AppStatusTone.warning,
          child: Text(
            l10n.onboardingRecoveryWarning,
            style: typography.body.copyWith(color: colors.ink200),
          ),
        ),
        SizedBox(height: spacing.md),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < codes.length; i += 2) ...[
                if (i > 0) SizedBox(height: spacing.sm),
                Row(
                  children: [
                    Expanded(child: _RecoveryCodeText(code: codes[i])),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: i + 1 < codes.length
                          ? _RecoveryCodeText(code: codes[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: spacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppButton(
              variant: AppButtonVariant.outline,
              icon: AppIcons.copy,
              onPressed: () => _copyCodes(context),
              child: Text(l10n.onboardingCopyCodes),
            ),
            // Spacer(),
            // Expanded(child: SizedBox(width: spacing.sm)),
            AppButton(
              variant: AppButtonVariant.outline,
              icon: AppIcons.download,
              onPressed: () => _downloadCodes(context),
              child: Text(l10n.onboardingDownloadCodes),
            ),
          ],
        ),
        SizedBox(height: spacing.md),
        AppCheckboxField(
          value: state.codesSaved,
          label: l10n.onboardingCodesSavedLabel,
          description: l10n.onboardingCodesSavedDescription,
          onChanged: (value) => onCodesSavedChanged(value ?? false),
        ),
      ],
    );
  }
}

class _RecoveryCodeText extends StatelessWidget {
  const _RecoveryCodeText({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      code,
      style: context.appTextStyles.label.copyWith(
        color: context.appColors.ink100,
        letterSpacing: 0.4,
      ),
    );
  }
}

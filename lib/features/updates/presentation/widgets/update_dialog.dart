// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/app/shell/help/widgets/help_about_panel.dart';
import 'package:khulla/core/config/app_info.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/presentation/cubit/update_cubit.dart';
import 'package:khulla/features/updates/presentation/cubit/update_state.dart';
import 'package:khulla/features/updates/presentation/cubit/update_status.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Is there a newer Khulla, and getting it.
///
/// A dialog rather than a page, opened from the account menu over whatever
/// the desk was doing - like *About*, it is looked up, not navigated to.
/// Closing it cancels nothing: the cubit is app-wide, so a download keeps
/// going and reopening the dialog finds it where it was.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog._();

  /// Opens the dialog and asks for the latest version.
  static Future<void> show(BuildContext context) {
    final cubit = context.read<UpdateCubit>();
    unawaited(cubit.checkForUpdate());
    return AppDialog.show<void>(
      context: context,
      title: context.l10n.updateDialogTitle,
      icon: AppIcons.appUpdate,
      iconTone: AppStatusTone.brand,
      content: BlocProvider.value(value: cubit, child: const UpdateDialog._()),
      actionsBuilder: (_) =>
          BlocProvider.value(value: cubit, child: const _UpdateActions()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final state = context.watch<UpdateCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _UpdateBody(state: state),
        if (state.channel.checksForUpdates) ...[
          SizedBox(height: spacing.md),
          Divider(height: 1, color: colors.hairline),
          SizedBox(height: spacing.sm),
          AppSwitchField(
            value: state.automaticChecks,
            label: context.l10n.updateAutoCheckLabel,
            description: context.l10n.updateAutoCheckDescription,
            onChanged: (enabled) => context
                .read<UpdateCubit>()
                .setAutomaticUpdateChecks(enabled: enabled),
          ),
        ],
      ],
    );
  }
}

/// What the dialog says, for where the flow stands.
class _UpdateBody extends StatelessWidget {
  const _UpdateBody({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;
    final release = state.release;
    final running = state.runningVersion ?? '…';

    Text line(String text, {Color? color}) => Text(
      text,
      textAlign: TextAlign.center,
      style: typography.body.copyWith(color: color ?? colors.mutedForeground),
    );

    if (!state.channel.checksForUpdates) return line(l10n.updatePlayBody);

    final error = state.error;
    final failure = state.status == UpdateStatus.failed && error != null
        ? line(
            error.localizedMessage(l10n),
            color: AppStatusTone.danger.foreground(context),
          )
        : null;

    if (release == null) {
      return switch (state.status) {
        UpdateStatus.upToDate => line(l10n.updateUpToDate(running)),
        UpdateStatus.failed => failure ?? line(l10n.updateChecking),
        _ => line(l10n.updateChecking),
      };
    }

    final next = switch (state.channel) {
      UpdateChannel.windowsInstaller => switch (state.status) {
        UpdateStatus.downloading => AppProgressBar(
          value: state.progress,
          label: l10n.updateDownloading,
          valueLabel: l10n.updateDownloadProgress(
            '${(state.progress * 100).floor()}',
          ),
        ),
        UpdateStatus.readyToInstall ||
        UpdateStatus.installing => line(l10n.updateReadyBody),
        _ => null,
      },
      UpdateChannel.web => line(l10n.updateWebBody),
      _ => line(l10n.updateManualBody),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        line(
          l10n.updateAvailable(release.version, running),
          color: colors.textHigh,
        ),
        SizedBox(height: spacing.xxs),
        Center(
          child: AppButton(
            variant: AppButtonVariant.link,
            onPressed: () =>
                HelpAboutPanel.openLink(context, '${release.notesUrl}'),
            child: Text(l10n.updateWhatsNew),
          ),
        ),
        if (next != null) ...[SizedBox(height: spacing.md), next],
        if (failure != null) ...[SizedBox(height: spacing.sm), failure],
      ],
    );
  }
}

/// The footer: close, and the one step the flow is waiting on.
class _UpdateActions extends StatelessWidget {
  const _UpdateActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<UpdateCubit>().state;
    final cubit = context.read<UpdateCubit>();

    final close = AppDialog.secondaryAction(
      context: context,
      label: l10n.commonClose,
      onPressed: () => Navigator.of(context).pop(),
    );

    Widget primary(String label, VoidCallback onPressed) =>
        AppDialog.primaryAction(
          context: context,
          label: label,
          onPressed: onPressed,
          isLoading: state.isBusy,
        );

    final release = state.release;
    final action = switch (state.status) {
      _ when !state.channel.checksForUpdates => primary(
        l10n.updatePlayAction,
        () => HelpAboutPanel.openLink(context, AppInfo.playStoreUrl),
      ),
      UpdateStatus.failed => primary(l10n.commonRetry, cubit.retryUpdate),
      UpdateStatus.idle || UpdateStatus.upToDate => null,
      UpdateStatus.checking => primary(l10n.shellCheckForUpdates, () {}),
      _ when release == null => null,
      _ => switch (state.channel) {
        UpdateChannel.windowsInstaller =>
          state.status == UpdateStatus.readyToInstall ||
                  state.status == UpdateStatus.installing
              ? primary(l10n.updateInstallAction, cubit.installUpdate)
              : primary(l10n.updateDownloadAction, cubit.downloadUpdate),
        UpdateChannel.web => primary(
          l10n.updateWebAction,
          cubit.installUpdate,
        ),
        _ => primary(
          l10n.updateManualAction,
          () => HelpAboutPanel.openLink(context, '${release.notesUrl}'),
        ),
      },
    };

    return AppDialogActions(children: [close, ?action]);
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/backup_state.dart';
import 'package:khulla/features/settings/presentation/widgets/confirm_erase_dialog.dart';
import 'package:khulla/features/settings/presentation/widgets/settings_action_card.dart';
import 'package:khulla/features/settings/presentation/widgets/settings_erase_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Export, restore - and the one irreversible action in the app.
///
/// Khulla is local-first: there is no server holding a second copy of any of
/// this. The erase entry sits below the routine actions as one more quiet
/// row rather than an alarm panel - the danger lives in its button, and the
/// confirmation dialog behind it is what stops an accident.
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  Future<void> _export(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<BackupCubit>();
    try {
      final exported = await cubit.exportBackup();
      if (!context.mounted || !exported) return;
      AppToast.success(context, message: l10n.settingsBackupExported);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.settingsBackupRestoreConfirmTitle,
      message: l10n.settingsBackupRestoreConfirmBody,
      confirmLabel: l10n.settingsBackupRestoreAction,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;

    final cubit = context.read<BackupCubit>();
    try {
      // On success this never returns to a running screen - `restartApp()`
      // ends the process (or reloads the page on web) before the app can
      // draw another frame from a catalogue that is being replaced under it.
      await cubit.restoreBackup();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _confirmErase(BuildContext context) async {
    final l10n = context.l10n;
    // The dialog already demanded the operator's password: true means
    // verified, so the erase proceeds with no second prompt.
    final confirmed = await ConfirmEraseDialog.show(context);
    if (!context.mounted || !confirmed) return;

    final cubit = context.read<BackupCubit>();
    try {
      await cubit.eraseCatalogue();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupCubit, BackupState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        return _BackupBody(
          state: state,
          onExport: () => unawaited(_export(context)),
          onRestore: () => unawaited(_restore(context)),
          onErase: () => unawaited(_confirmErase(context)),
        );
      },
    );
  }
}

class _BackupBody extends StatelessWidget {
  const _BackupBody({
    required this.state,
    required this.onExport,
    required this.onRestore,
    required this.onErase,
  });

  final BackupState state;
  final VoidCallback onExport;
  final VoidCallback onRestore;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final info = state.info;

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
                SectionCard(
                  title: l10n.settingsBackupTitle,
                  subtitle: l10n.settingsBackupBody,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppDetailRow(
                        label: l10n.settingsBackupLastBackup,
                        child: Text(
                          info?.lastBackupAt == null
                              ? l10n.settingsBackupNever
                              : AppDateFormat.format(info!.lastBackupAt!),
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      AppDetailRow(
                        label: l10n.settingsBackupDatabaseSize,
                        child: Text(
                          info?.databaseSizeBytes == null
                              ? l10n.commonUnavailable
                              : _formatBytes(info!.databaseSizeBytes!),
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      AppDetailRow(
                        label: l10n.settingsAboutStorage,
                        child: Text(
                          info?.storagePath ?? l10n.commonUnavailable,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.md),
                AppResponsiveGrid(
                  largeColumns: 2,
                  children: [
                    SettingsActionCard(
                      title: l10n.settingsBackupExportTitle,
                      description: l10n.settingsBackupExportBody,
                      actionLabel: l10n.settingsBackupExportAction,
                      icon: AppIcons.download,
                      isLoading: state.isWorking,
                      onAction: onExport,
                    ),
                    SettingsActionCard(
                      title: l10n.settingsBackupRestoreTitle,
                      description: l10n.settingsBackupRestoreBody,
                      actionLabel: l10n.settingsBackupRestoreAction,
                      icon: AppIcons.restore,
                      isLoading: state.isWorking,
                      onAction: onRestore,
                    ),
                  ],
                ),
                SizedBox(height: spacing.lg),
                SettingsEraseCard(
                  title: l10n.settingsBackupEraseTitle,
                  description: l10n.settingsBackupEraseBody,
                  actionLabel: l10n.settingsBackupEraseAction,
                  isLoading: state.isWorking,
                  onAction: onErase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(2)} GB';
}

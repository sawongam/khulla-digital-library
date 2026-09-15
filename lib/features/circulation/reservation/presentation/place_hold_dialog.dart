// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/features/circulation/reservation/presentation/cubit/place_hold_cubit.dart';
import 'package:khulla/features/circulation/reservation/presentation/cubit/place_hold_state.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/widgets/empty_result_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Queues a member on a title.
class PlaceHoldDialog extends StatelessWidget {
  const PlaceHoldDialog({this.titleId, super.key});

  final String? titleId;

  static Future<bool?> show(BuildContext context, {String? titleId}) =>
      AppFormModal.show<bool>(
        context: context,
        builder: (_) => BlocProvider(
          create: (_) {
            final cubit = getIt<PlaceHoldCubit>();
            unawaited(cubit.load(titleId: titleId));
            return cubit;
          },
          child: PlaceHoldDialog(titleId: titleId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlaceHoldCubit, PlaceHoldState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppFormModal(
            title: l10n.placeHoldHeading,
            width: AppDialogWidth.xxxl,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }

        return _PlaceHoldBody(state: state);
      },
    );
  }
}

class _PlaceHoldBody extends StatelessWidget {
  const _PlaceHoldBody({required this.state});

  final PlaceHoldState state;

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await context.read<PlaceHoldCubit>().placeHold();
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final cubit = context.read<PlaceHoldCubit>();
    final fixed = state.fixedTitle;
    final selected = state.selectedTitle;
    final member = state.member;

    return AppFormModal(
      title: l10n.placeHoldHeading,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.reservationsPlace,
          isLoading: state.isSaving,
          onPressed: () => unawaited(_save(context)),
        ),
      ],
      children: [
        AppFormSection(
          title: l10n.checkOutMemberSection,
          children: [
            if (member == null)
              AppSearchField(
                hintText: l10n.checkOutMemberHint,
                clearTooltip: l10n.commonClearSearch,
                onChanged: cubit.memberSearchChanged,
              )
            else
              Row(
                children: [
                  AppAvatar(initials: member.initials),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.fullName,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          member.barcode,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppTextButton(
                    onPressed: cubit.clearMember,
                    child: Text(l10n.checkOutChangeMember),
                  ),
                ],
              ),
            if (state.isLookingUpMember) ...[
              SizedBox(height: spacing.sm),
              const Center(child: AppSpinner()),
            ],
            if (member == null &&
                !state.isLookingUpMember &&
                state.memberMatches.isNotEmpty) ...[
              SizedBox(height: spacing.sm),
              for (final match in state.memberMatches)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xxs),
                  child: _MemberPickRow(
                    member: match,
                    onTap: () => cubit.memberSelected(match),
                  ),
                ),
            ],
            if (member == null &&
                !state.isLookingUpMember &&
                state.memberMatches.isEmpty &&
                state.memberQuery.isNotEmpty) ...[
              SizedBox(height: spacing.sm),
              EmptyResultView(
                variant: AppFeedbackVariant.inline,
                title: l10n.commonNoMatchesTitle,
                subtitle: l10n.commonNoMatchesBody,
              ),
            ],
          ],
        ),
        AppFormSection(
          title: l10n.reservationsColumnTitle,
          children: [
            if (fixed != null)
              AppDetailRow(
                label: l10n.titlesColumnTitle,
                child: Text(fixed.title),
              )
            else ...[
              AppSearchField(
                hintText: l10n.titlesSearchHint,
                clearTooltip: l10n.commonClearSearch,
                onChanged: cubit.titleSearchChanged,
              ),
              if (selected != null) ...[
                SizedBox(height: spacing.sm),
                AppDetailRow(
                  label: l10n.titlesColumnTitle,
                  child: Text(selected.title),
                ),
              ],
              if (state.titleMatches.isNotEmpty) ...[
                SizedBox(height: spacing.sm),
                for (final title in state.titleMatches)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.xxs),
                    child: _TitlePickRow(
                      title: title,
                      selected: selected?.id == title.id,
                      onTap: () => cubit.titleSelected(title),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ],
    );
  }
}

/// One tappable member in the lookup matches.
class _MemberPickRow extends StatelessWidget {
  const _MemberPickRow({required this.member, required this.onTap});

  final Member member;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final spacing = context.appSpacing;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(initials: member.initials),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  member.barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitlePickRow extends StatelessWidget {
  const _TitlePickRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final catalog.Title title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  title.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            AppIcon(AppIcons.success, color: scheme.primary, size: 18),
        ],
      ),
    );
  }
}

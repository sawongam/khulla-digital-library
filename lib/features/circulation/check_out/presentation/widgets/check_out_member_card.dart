// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla/shared/widgets/empty_result_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Who the copies are going home with.
///
/// Empty first, on purpose: the loan period, the borrowing limit and whether
/// the desk may lend at all come from the member's category, so the screen
/// asks for the card before it asks for a barcode.
///
/// Typing lists matches and the desk picks one — nothing is selected
/// automatically, except an exact card-number hit, which is a scan.
class CheckOutMemberCard extends StatelessWidget {
  const CheckOutMemberCard({
    required this.onSearchChanged,
    required this.onChangeMember,
    required this.onSelectMember,
    required this.memberName,
    required this.memberCard,
    required this.memberCategory,
    required this.outstandingFines,
    required this.initials,
    required this.matches,
    required this.isSearching,
    required this.hasQuery,
    super.key,
  });

  /// Reports the lookup query. A cubit debounces it and runs the search.
  final ValueChanged<String> onSearchChanged;

  /// Clears the chosen member and returns the card to its lookup state.
  final VoidCallback onChangeMember;

  /// Picks one member from the search matches.
  final ValueChanged<Member> onSelectMember;

  /// The chosen member, or null while none has been picked.
  final String? memberName;

  final String? memberCard;
  final String? memberCategory;

  /// What they already owe — the thing a desk needs to see before lending
  /// again, not after.
  final Money outstandingFines;

  /// Two ready-made letters for the avatar.
  final String? initials;

  /// Members matching the current query — the desk taps one to choose it.
  final List<Member> matches;

  /// Whether a search is in flight.
  final bool isSearching;

  /// Whether the desk has typed anything yet.
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final name = memberName;

    return SectionCard(
      title: l10n.checkOutMemberSection,
      trailing: name == null
          ? null
          : AppTextButton(
              onPressed: onChangeMember,
              child: Text(l10n.checkOutChangeMember),
            ),
      child: name == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSearchField(
                  hintText: l10n.checkOutMemberHint,
                  clearTooltip: l10n.commonClearSearch,
                  onChanged: onSearchChanged,
                ),
                SizedBox(height: spacing.md),
                if (isSearching)
                  const Center(child: AppSpinner())
                else if (matches.isNotEmpty)
                  for (final match in matches)
                    Padding(
                      padding: EdgeInsets.only(bottom: spacing.xxs),
                      child: _MemberPickRow(
                        member: match,
                        onTap: () => onSelectMember(match),
                      ),
                    )
                else if (hasQuery)
                  EmptyResultView(
                    variant: AppFeedbackVariant.inline,
                    title: l10n.commonNoMatchesTitle,
                    subtitle: l10n.commonNoMatchesBody,
                  )
                else
                  AppEmptyView(
                    variant: AppFeedbackVariant.inline,
                    title: l10n.checkOutMemberEmptyTitle,
                    message: l10n.checkOutMemberEmptyBody,
                  ),
              ],
            )
          : Row(
              children: [
                AppAvatar(initials: initials ?? '', size: 48),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing.xxs),
                      Text(
                        '${memberCard ?? ''} · ${memberCategory ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (outstandingFines.isPositive)
                  AppStatusBadge(
                    label: outstandingFines.display(),
                    tone: AppStatusTone.danger,
                    icon: AppIcons.wallet,
                  ),
              ],
            ),
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
                  '${member.barcode} · ${member.memberTypeName}',
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

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/check_out/presentation/cubit/check_out_cubit.dart';
import 'package:khulla/features/circulation/check_out/presentation/cubit/check_out_state.dart';
import 'package:khulla/features/circulation/check_out/presentation/widgets/check_out_basket.dart';
import 'package:khulla/features/circulation/check_out/presentation/widgets/check_out_member_card.dart';
import 'package:khulla/features/circulation/check_out/presentation/widgets/check_out_summary_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/collection_header.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The checkout desk: a member, a basket of copies, and one button.
///
/// Two panes from [FormFactor.expanded] up, with the summary on the right
/// where it stays visible as copies are scanned; one column below that. The
/// scan field never leaves the top of the basket, because the barcode reader
/// is the only input a busy desk uses.
///
/// [CheckOutCubit] owns the chosen member and the basket; `checkOutCopies()`
/// names the outcome rather than the gesture, and a failed write answers as a
/// toast - not as a screen state.
class CheckOutPage extends StatefulWidget {
  const CheckOutPage({super.key});

  @override
  State<CheckOutPage> createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> with DisposeBag {
  late final TextEditingController _scan = textController();

  Future<void> _scanCopy(String barcode) async {
    final cubit = context.read<CheckOutCubit>();
    final l10n = context.l10n;
    try {
      await cubit.addCopyByBarcode(barcode);
      if (!mounted) return;
      _scan.clear();
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _confirmCheckout() async {
    final cubit = context.read<CheckOutCubit>();
    final l10n = context.l10n;
    try {
      await cubit.checkOutCopies();
      if (!mounted) return;
      AppToast.success(context, message: l10n.checkOutSuccess);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final twoPane = context.formFactor.isAtLeast(FormFactor.expanded);
    final cubit = context.read<CheckOutCubit>();

    return BlocConsumer<CheckOutCubit, CheckOutState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        final error = state.error;
        if (error == null) return;
        AppToast.error(context, message: error.localizedMessage(l10n));
      },
      builder: (context, state) {
        final member = state.member;

        final memberCard = CheckOutMemberCard(
          memberName: member?.fullName,
          memberCard: member?.barcode,
          memberCategory: member?.memberTypeName,
          initials: member?.initials,
          outstandingFines: member?.finesOwed ?? Money.zero,
          matches: state.memberMatches,
          isSearching: state.isLookingUpMember,
          hasQuery: state.memberQuery.isNotEmpty,
          onSearchChanged: cubit.memberSearchChanged,
          onChangeMember: cubit.clearMember,
          onSelectMember: (match) => unawaited(cubit.memberSelected(match)),
        );

        final basket = CheckOutBasket(
          copies: state.basket,
          scanController: _scan,
          onScanSubmitted: (value) => unawaited(_scanCopy(value)),
          onRemove: cubit.removeCopy,
        );

        final summary = CheckOutSummaryCard(
          copyCount: state.basket.length,
          loanPeriodDays: state.loanPeriodDays,
          dueDate: cubit.dueDateLabel(),
          borrowingLimit: state.borrowingLimit,
          currentLoansOut: member?.loansOut ?? 0,
          outstandingFines: member?.finesOwed ?? Money.zero,
          onConfirm: state.canConfirm && !state.isOverBorrowingLimit
              ? () => unawaited(_confirmCheckout())
              : null,
        );

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
                    CollectionHeader(
                      title: l10n.checkOutHeading,
                      subtitle: l10n.checkOutSubtitle,
                    ),
                    SizedBox(height: spacing.lg),
                    if (twoPane)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                memberCard,
                                SizedBox(height: spacing.md),
                                basket,
                              ],
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(flex: 2, child: summary),
                        ],
                      )
                    else ...[
                      memberCard,
                      SizedBox(height: spacing.md),
                      basket,
                      SizedBox(height: spacing.md),
                      summary,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

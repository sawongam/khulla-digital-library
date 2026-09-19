// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/circulation/return_copy/presentation/cubit/return_cubit.dart';
import 'package:khulla/features/circulation/return_copy/presentation/cubit/return_state.dart';
import 'package:khulla/features/circulation/return_copy/presentation/widgets/return_basket.dart';
import 'package:khulla/features/circulation/return_copy/presentation/widgets/return_summary_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/collection_header.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The returns desk: scan, price, confirm.
///
/// A return is several writes in one gesture — the copy goes back on the
/// shelf, the loan closes, a fine may be raised, and a hold behind the title
/// may become ready. That is why the confirm button is one button at the
/// bottom of a summary, rather than an action per row.
///
/// [ReturnCubit] owns the basket, the waive-fines toggle and the reported
/// condition; `returnCopies()` runs the transaction.
class ReturnPage extends StatefulWidget {
  const ReturnPage({super.key});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> with DisposeBag {
  late final TextEditingController _scan = textController();

  Future<void> _scanCopy(String barcode) async {
    final cubit = context.read<ReturnCubit>();
    final l10n = context.l10n;
    try {
      await cubit.addLoanByBarcode(barcode);
      if (!mounted) return;
      _scan.clear();
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _confirmReturn() async {
    final cubit = context.read<ReturnCubit>();
    final l10n = context.l10n;
    try {
      await cubit.returnCopies();
      if (!mounted) return;
      AppToast.success(context, message: l10n.returnsSuccess);
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
    final cubit = context.read<ReturnCubit>();

    return BlocBuilder<ReturnCubit, ReturnState>(
      builder: (context, state) {
        final basket = ReturnBasket(
          loans: state.basket,
          scanController: _scan,
          onScanSubmitted: (value) => unawaited(_scanCopy(value)),
          onRemove: cubit.removeLoan,
        );

        final summary = ReturnSummaryCard(
          copyCount: state.basket.length,
          lateCount: state.lateCount,
          finesDue: state.finesDue,
          waiveFines: state.waiveFines,
          onWaiveChanged: cubit.waiveFinesChanged,
          condition: state.condition,
          onConditionChanged: cubit.conditionChanged,
          onConfirm: state.canConfirm
              ? () => unawaited(_confirmReturn())
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
                      title: l10n.returnsHeading,
                      subtitle: l10n.returnsSubtitle,
                    ),
                    SizedBox(height: spacing.lg),
                    if (twoPane)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: basket),
                          SizedBox(width: spacing.md),
                          Expanded(flex: 2, child: summary),
                        ],
                      )
                    else ...[
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

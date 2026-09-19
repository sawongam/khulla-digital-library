// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:country_phone_kit/country_phone_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_state.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Step one: what the library is called, and what it charges in.
///
/// The controller is seeded from [state] rather than kept in the widget, so
/// stepping back from the account step returns a filled-in form.
class OnboardingLibraryStep extends StatefulWidget {
  const OnboardingLibraryStep({required this.state, super.key});

  final OnboardingState state;

  @override
  State<OnboardingLibraryStep> createState() => _OnboardingLibraryStepState();
}

class _OnboardingLibraryStepState extends State<OnboardingLibraryStep>
    with DisposeBag {
  late final TextEditingController _name = textController(
    widget.state.libraryName.value,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final cubit = context.read<OnboardingCubit>();
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: l10n.onboardingLibraryNameLabel,
          hintText: l10n.onboardingLibraryNameHint,
          required: true,
          autofocus: true,
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: state.libraryName.messageFor(l10n),
          onChanged: cubit.libraryNameChanged,
        ),
        SizedBox(height: spacing.sm),
        AppDropdownField<CountryCurrency>(
          label: l10n.onboardingCurrencyLabel,
          required: true,
          value: Currencies.byCode(state.currency.code),
          items: Currencies.all,
          itemLabel: (currency) => '${currency.name} (${currency.code})',
          searchHint: l10n.currencySearchHint,
          clearSearchTooltip: l10n.commonClearSearch,
          emptySearchMessage: l10n.commonNoMatchesTitle,
          itemMatchesSearch: (currency, query) => currency.matchesQuery(query),
          onChanged: (currency) {
            if (currency != null) {
              cubit.currencyChanged(AppCurrency.fromCountryCurrency(currency));
            }
          },
        ),
        SizedBox(height: spacing.xs),
        Text(
          l10n.onboardingCurrencyHelp,
          style: typography.caption.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

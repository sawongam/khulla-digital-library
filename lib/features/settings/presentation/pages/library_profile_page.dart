// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:file_selector/file_selector.dart' show XTypeGroup, openFile;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_state.dart';
import 'package:khulla/features/settings/presentation/widgets/settings_logo_crop_dialog.dart';
import 'package:khulla/features/settings/presentation/widgets/settings_logo_field.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/presentation/cubit/library_branding_cubit.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla/shared/widgets/view_only_notice.dart';
import 'package:khulla_ui/khulla_ui.dart';

class LibraryProfilePage extends StatefulWidget {
  const LibraryProfilePage({super.key});

  @override
  State<LibraryProfilePage> createState() => _LibraryProfilePageState();
}

class _LibraryProfilePageState extends State<LibraryProfilePage>
    with DisposeBag {
  late final TextEditingController _name = textController();
  late final TextEditingController _email = textController();
  late final TextEditingController _phone = textController();
  late final TextEditingController _address = textController();
  late final TextEditingController _openingHours = textController();
  late final TextEditingController _barcodePrefix = textController();
  late final TextEditingController _barcodeNextValue = textController();
  late final TextEditingController _memberBarcodePrefix = textController();
  late final TextEditingController _memberBarcodeNextValue = textController();
  late final TextEditingController _staffBarcodePrefix = textController();
  late final TextEditingController _staffBarcodeNextValue = textController();

  /// Copies the cubit's form into the text fields. Runs only when the cubit
  /// (re)fills the form from a saved profile - never while someone types.
  void _fillFields(LibraryProfileState state) {
    _name.text = state.name.value;
    _email.text = state.email;
    _phone.text = state.phone;
    _address.text = state.address;
    _openingHours.text = state.openingHours;
    _barcodePrefix.text = state.barcodePrefix.value;
    _barcodeNextValue.text = state.barcodeNextValue.value;
    _memberBarcodePrefix.text = state.memberBarcodePrefix.value;
    _memberBarcodeNextValue.text = state.memberBarcodeNextValue.value;
    _staffBarcodePrefix.text = state.staffBarcodePrefix.value;
    _staffBarcodeNextValue.text = state.staffBarcodeNextValue.value;
  }

  Future<void> _uploadLogo(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Image',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final pickedBytes = await picked.readAsBytes();
    if (!context.mounted) return;

    final cropped = await SettingsLogoCropDialog.show(
      context,
      imageBytes: pickedBytes,
    );
    if (cropped == null) return;
    if (!context.mounted) return;

    try {
      // The cropper always re-encodes to PNG, whatever the source format was.
      await context.read<LibraryProfileCubit>().uploadLogo(cropped, 'png');
      if (!context.mounted) return;
      await context.read<LibraryBrandingCubit>().refreshLogo();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _removeLogo(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await context.read<LibraryProfileCubit>().removeLogo();
      if (!context.mounted) return;
      await context.read<LibraryBrandingCubit>().refreshLogo();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final saved = await context.read<LibraryProfileCubit>().saveProfile();
      if (!context.mounted) return;
      if (!saved) {
        AppToast.error(context, message: l10n.validationFieldRequired);
        return;
      }
      AppToast.success(context, message: l10n.settingsLibrarySave);
      context.go(Routes.settings);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        message: error.localizedMessage(l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    // The library's own settings read at `view` and write at `manage`, so a
    // librarian can answer "how long is a loan" without being able to change
    // the answer. The form stays legible and stops accepting input.
    final viewOnly = !context.canManage(StaffPermission.settings);
    const numberInput = TextInputType.number;

    final cubit = context.read<LibraryProfileCubit>();

    return BlocConsumer<LibraryProfileCubit, LibraryProfileState>(
      listenWhen: (previous, current) =>
          current.formRevision != previous.formRevision,
      listener: (context, state) => _fillFields(state),
      builder: (context, state) {
        if (state.isLoading) {
          return const AppPageBody(
            wide: true,
            child: Center(child: AppSpinner()),
          );
        }
        if (state.hasError) {
          return AppPageBody(
            wide: true,
            child: ErrorRetryView(
              error: state.error,
              onRetry: cubit.loadProfile,
            ),
          );
        }
        if (state.profile == null) {
          return AppPageBody(
            wide: true,
            child: AppEmptyView(
              icon: AppIcons.settings,
              title: l10n.settingsLibraryIdentity,
              message: l10n.onboardingLibrarySubtitle,
            ),
          );
        }

        return AppPageBody(
          wide: true,
          child: ViewOnlyForm(
            viewOnly: viewOnly,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.page,
                spacing.lg,
                spacing.page,
                spacing.xlg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (viewOnly) ...[
                    const ViewOnlyNotice(),
                    SizedBox(height: spacing.md),
                  ],
                  AppFormSection(
                    title: l10n.settingsLibraryIdentity,
                    description: l10n.settingsLibraryIdentityDescription,
                    children: [
                      AppTextField(
                        label: l10n.fieldLibraryName,
                        required: true,
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        onChanged: cubit.libraryNameChanged,
                        errorText: state.name.messageFor(l10n),
                      ),
                      if (!viewOnly) ...[
                        SizedBox(height: spacing.md),
                        SettingsLogoField(
                          logoBytes: state.logoBytes,
                          isSaving: state.isSavingLogo,
                          onUpload: () => unawaited(_uploadLogo(context)),
                          onRemove: state.logoBytes == null
                              ? null
                              : () => unawaited(_removeLogo(context)),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  AppFormSection(
                    title: l10n.settingsLibraryContact,
                    description: l10n.settingsLibraryContactDescription,
                    children: [
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldEmail,
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: cubit.emailChanged,
                          ),
                          AppTextField(
                            label: l10n.fieldPhone,
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            onChanged: cubit.phoneChanged,
                          ),
                        ],
                      ),
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldAddress,
                            controller: _address,
                            textCapitalization: TextCapitalization.words,
                            onChanged: cubit.addressChanged,
                          ),
                          AppTextField(
                            label: l10n.fieldOpeningHours,
                            controller: _openingHours,
                            onChanged: cubit.openingHoursChanged,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  AppFormSection(
                    title: l10n.settingsLibraryLocale,
                    description: l10n.settingsLibraryLocaleDescription,
                    children: [
                      AppDropdownField<AppCurrency>(
                        label: l10n.fieldCurrency,
                        required: true,
                        value: state.currency,
                        items: AppCurrency.values,
                        itemLabel: (currency) => currency.label(l10n),
                        searchHint: l10n.currencySearchHint,
                        clearSearchTooltip: l10n.commonClearSearch,
                        emptySearchMessage: l10n.commonNoMatchesTitle,
                        itemMatchesSearch: (currency, query) =>
                            currency.name.toLowerCase().contains(query) ||
                            currency.code.toLowerCase().contains(query),
                        onChanged: (currency) {
                          if (currency != null) cubit.currencyChanged(currency);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  AppFormSection(
                    title: l10n.settingsLibraryBarcodes,
                    description: l10n.settingsLibraryBarcodesDescription,
                    children: [
                      Text(
                        l10n.settingsLibraryBarcodesCopies,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldBarcodePrefix,
                            required: true,
                            controller: _barcodePrefix,
                            onChanged: cubit.barcodePrefixChanged,
                            errorText: state.barcodePrefix.messageFor(l10n),
                          ),
                          AppTextField(
                            label: l10n.fieldBarcodeNextValue,
                            required: true,
                            controller: _barcodeNextValue,
                            keyboardType: numberInput,
                            onChanged: cubit.barcodeNextValueChanged,
                            errorText: state.barcodeNextValue.messageFor(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        l10n.settingsLibraryBarcodesMembers,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldBarcodePrefix,
                            required: true,
                            controller: _memberBarcodePrefix,
                            onChanged: cubit.memberBarcodePrefixChanged,
                            errorText: state.memberBarcodePrefix.messageFor(
                              l10n,
                            ),
                          ),
                          AppTextField(
                            label: l10n.fieldBarcodeNextValue,
                            required: true,
                            controller: _memberBarcodeNextValue,
                            keyboardType: numberInput,
                            onChanged: cubit.memberBarcodeNextValueChanged,
                            errorText: state.memberBarcodeNextValue.messageFor(
                              l10n,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        l10n.settingsLibraryBarcodesStaff,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldBarcodePrefix,
                            required: true,
                            controller: _staffBarcodePrefix,
                            onChanged: cubit.staffBarcodePrefixChanged,
                            errorText: state.staffBarcodePrefix.messageFor(
                              l10n,
                            ),
                          ),
                          AppTextField(
                            label: l10n.fieldBarcodeNextValue,
                            required: true,
                            controller: _staffBarcodeNextValue,
                            keyboardType: numberInput,
                            onChanged: cubit.staffBarcodeNextValueChanged,
                            errorText: state.staffBarcodeNextValue.messageFor(
                              l10n,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xlg),
                  if (!viewOnly)
                    Row(
                      children: [
                        const Spacer(),
                        AppButton(
                          size: AppButtonSize.medium,
                          isLoading: state.isSaving,
                          onPressed: state.isSaving
                              ? null
                              : () => unawaited(_save(context)),
                          child: Text(l10n.settingsLibrarySave),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

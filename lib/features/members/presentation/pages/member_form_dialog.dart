// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/cubit/member_form_cubit.dart';
import 'package:khulla/features/members/presentation/cubit/member_form_state.dart';
import 'package:khulla/features/members/presentation/widgets/create_category_form.dart';
import 'package:khulla/features/members/presentation/widgets/member_form_membership_section.dart';
import 'package:khulla/features/members/presentation/widgets/member_form_sections.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/presentation/cubit/reference_data_cubit.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The borrower editor, used for both a new card and an existing one.
///
/// A modal rather than a route — see [AppFormModal]. Four sections in the
/// order the counter fills them: identity, contact, additional details and
/// membership. [MemberFormCubit] loads member types and saves the record;
/// barcode is auto-generated from library settings when blank.
class MemberFormDialog extends StatelessWidget {
  const MemberFormDialog({this.memberId, super.key});

  final String? memberId;

  static Future<bool?> show(BuildContext context, {String? memberId}) =>
      AppFormModal.show<bool>(
        context: context,
        builder: (_) => BlocProvider(
          create: (_) {
            final cubit = getIt<MemberFormCubit>();
            unawaited(cubit.load(memberId: memberId));
            return cubit;
          },
          child: MemberFormDialog(memberId: memberId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = memberId != null;

    return BlocBuilder<MemberFormCubit, MemberFormState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppFormModal(
            title: isEditing
                ? l10n.memberFormEditHeading
                : l10n.memberFormNewHeading,
            width: AppDialogWidth.xxxl,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }

        return _MemberFormBody(
          key: ValueKey(memberId ?? 'new'),
          memberId: memberId,
          existing: state.existing,
          memberTypes: state.memberTypes,
          isSaving: state.isSaving,
        );
      },
    );
  }
}

class _MemberFormBody extends StatefulWidget {
  const _MemberFormBody({
    required this.memberId,
    required this.existing,
    required this.memberTypes,
    required this.isSaving,
    super.key,
  });

  final String? memberId;
  final Member? existing;
  final List<MemberType> memberTypes;
  final bool isSaving;

  @override
  State<_MemberFormBody> createState() => _MemberFormBodyState();
}

class _MemberFormBodyState extends State<_MemberFormBody> with DisposeBag {
  late final TextEditingController _name = textController(
    widget.existing?.fullName,
  );
  late Gender? _gender = widget.existing?.gender;
  late final TextEditingController _email = textController(
    widget.existing?.email,
  );
  late final TextEditingController _phone = textController(
    widget.existing?.phone,
  );
  late final TextEditingController _address = textController(
    widget.existing?.address,
  );
  late final TextEditingController _municipality = textController(
    widget.existing?.municipality,
  );
  late final TextEditingController _occupation = textController(
    widget.existing?.occupation,
  );
  late final TextEditingController _institution = textController(
    widget.existing?.institution,
  );
  late final TextEditingController _idVerification = textController(
    widget.existing?.idVerification,
  );
  late final TextEditingController _emergencyContactName = textController(
    widget.existing?.emergencyContactName,
  );
  late final TextEditingController _emergencyContactPhone = textController(
    widget.existing?.emergencyContactPhone,
  );
  late DateTime? _dateOfBirth = widget.existing?.dateOfBirth;
  late BloodGroup? _bloodGroup = widget.existing?.bloodGroup;
  late final TextEditingController _guardian = textController(
    widget.existing?.guardian,
  );
  late final TextEditingController _notes = textController(
    widget.existing?.notes,
  );

  late String _memberTypeId =
      widget.existing?.memberTypeId ??
      _memberTypeIdForNewMember(widget.memberTypes);

  /// New cards default to the public category; fall back to the first active
  /// type when that system category was archived or renamed away.
  static String _memberTypeIdForNewMember(List<MemberType> types) {
    for (final type in types) {
      if (type.code == 'public') return type.id;
    }
    return types.isNotEmpty ? types.first.id : '';
  }

  late bool _sendNotices = widget.existing?.sendNotices ?? true;
  late final String _expires = widget.existing?.expires ?? '';
  late final String _barcode = widget.existing?.barcode ?? '';

  bool get _isEditing => widget.memberId != null;

  MemberType? get _selectedType {
    for (final type in widget.memberTypes) {
      if (type.id == _memberTypeId) return type;
    }
    return widget.memberTypes.isEmpty ? null : widget.memberTypes.first;
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(today.year - 18),
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _dateOfBirth = DateTime(picked.year, picked.month, picked.day),
    );
  }

  Future<String?> _askCategoryName() {
    return AppFormModal.show<String>(
      context: context,
      builder: (modalContext) => const CreateCategoryForm(),
    );
  }

  Future<void> _addCategory() async {
    final name = await _askCategoryName();
    if (name == null || name.isEmpty || !mounted) return;
    final l10n = context.l10n;
    try {
      final type = await context.read<MemberFormCubit>().addMemberType(name);
      if (!mounted) return;
      unawaited(context.read<ReferenceDataCubit>().refreshMemberTypes());
      setState(() => _memberTypeId = type.id);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty || _memberTypeId.isEmpty) {
      AppToast.error(context, message: l10n.validationFieldRequired);
      return;
    }
    try {
      await context.read<MemberFormCubit>().saveMember(
        fullName: name,
        memberTypeId: _memberTypeId,
        sendNotices: _sendNotices,
        barcode: _barcode.isEmpty ? null : _barcode,
        gender: _gender,
        bloodGroup: _bloodGroup,
        municipality: _municipality.text.trim().isEmpty
            ? null
            : _municipality.text.trim(),
        occupation: _occupation.text.trim().isEmpty
            ? null
            : _occupation.text.trim(),
        institution: _institution.text.trim().isEmpty
            ? null
            : _institution.text.trim(),
        idVerification: _idVerification.text.trim().isEmpty
            ? null
            : _idVerification.text.trim(),
        emergencyContactName: _emergencyContactName.text.trim().isEmpty
            ? null
            : _emergencyContactName.text.trim(),
        emergencyContactPhone: _emergencyContactPhone.text.trim().isEmpty
            ? null
            : _emergencyContactPhone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        dateOfBirthText: _dateOfBirth == null
            ? null
            : AppDateFormat.format(_dateOfBirth!),
        guardian: _guardian.text.trim().isEmpty ? null : _guardian.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: _isEditing
          ? l10n.memberFormEditHeading
          : l10n.memberFormNewHeading,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: _close,
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.memberFormSave,
          isLoading: widget.isSaving,
          onPressed: () => unawaited(_save()),
        ),
      ],
      children: [
        MemberFormIdentitySection(
          name: _name,
          gender: _gender,
          onGenderChanged: (v) => setState(() => _gender = v),
          dateOfBirth: _dateOfBirth == null
              ? null
              : AppDateFormat.format(_dateOfBirth!),
          bloodGroup: _bloodGroup,
          onBloodGroupChanged: (v) => setState(() => _bloodGroup = v),
          guardian: _guardian,
          onPickDateOfBirth: () => unawaited(_pickDateOfBirth()),
          onClearDateOfBirth: _dateOfBirth == null
              ? null
              : () => setState(() => _dateOfBirth = null),
        ),
        MemberFormContactSection(
          email: _email,
          phone: _phone,
          address: _address,
          municipality: _municipality,
        ),
        MemberFormAdditionalSection(
          occupation: _occupation,
          institution: _institution,
          idVerification: _idVerification,
        ),
        MemberFormEmergencySection(
          emergencyContactName: _emergencyContactName,
          emergencyContactPhone: _emergencyContactPhone,
        ),
        MemberFormMembershipSection(
          memberTypes: widget.memberTypes,
          selectedType: _selectedType,
          expires: _expires,
          barcode: _barcode,
          notes: _notes,
          sendNotices: _sendNotices,
          onTypeChanged: (type) => setState(
            () => _memberTypeId = type?.id ?? _memberTypeId,
          ),
          onAddCategory: () => unawaited(_addCategory()),
          onSendNoticesChanged: (value) => setState(() => _sendNotices = value),
        ),
      ],
    );
  }
}

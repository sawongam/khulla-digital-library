// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_form_cubit.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_form_state.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/create_format_form.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_form_sections.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/presentation/cubit/reference_data_cubit.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The title editor, used for both a new work and an existing one.
///
/// A modal rather than a route — see [AppFormModal]. [TitleFormCubit] loads
/// formats and the existing record, then `saveTitle()` writes the bibliographic
/// fields and, on create, seeds the requested number of copies. Fields that are
/// genuinely independent pair up through [AppFormRow], which stacks them again
/// inside the narrower panel.
class TitleFormDialog extends StatelessWidget {
  const TitleFormDialog({this.titleId, super.key});

  final String? titleId;

  static Future<bool?> show(BuildContext context, {String? titleId}) =>
      AppFormModal.show<bool>(
        context: context,
        builder: (_) => BlocProvider(
          create: (_) {
            final cubit = getIt<TitleFormCubit>();
            unawaited(cubit.load(titleId: titleId));
            return cubit;
          },
          child: TitleFormDialog(titleId: titleId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = titleId != null;

    return BlocBuilder<TitleFormCubit, TitleFormState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppFormModal(
            title: isEditing
                ? l10n.titleFormEditHeading
                : l10n.titleFormNewHeading,
            width: AppDialogWidth.xxxl,
            actions: const [],
            children: const [Center(child: AppSpinner())],
          );
        }

        return _TitleFormBody(
          key: ValueKey(titleId ?? 'new'),
          titleId: titleId,
          existing: state.existing,
          formats: state.formats,
          isSaving: state.isSaving,
        );
      },
    );
  }
}

class _TitleFormBody extends StatefulWidget {
  const _TitleFormBody({
    required this.titleId,
    required this.existing,
    required this.formats,
    required this.isSaving,
    super.key,
  });

  final String? titleId;
  final catalog.Title? existing;
  final List<TitleFormat> formats;
  final bool isSaving;

  @override
  State<_TitleFormBody> createState() => _TitleFormBodyState();
}

class _TitleFormBodyState extends State<_TitleFormBody> with DisposeBag {
  late final TextEditingController _title = textController(
    widget.existing?.title,
  );
  late final TextEditingController _author = textController(
    widget.existing?.author,
  );
  late final TextEditingController _isbn = textController(
    widget.existing?.isbn,
  );
  late final TextEditingController _publisher = textController(
    widget.existing?.publisher,
  );
  late final TextEditingController _year = textController(
    widget.existing?.year,
  );
  late final TextEditingController _edition = textController(
    widget.existing?.edition,
  );
  late final TextEditingController _language = textController(
    widget.existing?.language ?? 'English',
  );
  late final TextEditingController _pages = textController(
    widget.existing?.pages?.toString(),
  );
  late final TextEditingController _shelf = textController(
    widget.existing?.shelf,
  );
  late final TextEditingController _description = textController(
    widget.existing?.description,
  );
  late final TextEditingController _replacementCost = textController(
    widget.existing?.replacementCost.editable,
  );
  late final TextEditingController _initialCopies = textController(
    _isEditing ? null : '1',
  );

  late String _formatId =
      widget.existing?.formatId ??
      (widget.formats.isNotEmpty ? widget.formats.first.id : '');
  late bool _lendable = widget.existing?.lendable ?? true;
  String? _titleError;
  String? _authorError;
  String? _formatError;
  String? _costError;
  String? _copiesError;

  bool get _isEditing => widget.titleId != null;

  TitleFormat? get _selectedFormat {
    for (final format in widget.formats) {
      if (format.id == _formatId) return format;
    }
    return widget.formats.isEmpty ? null : widget.formats.first;
  }

  void _close() => Navigator.of(context).pop();

  Future<String?> _askFormatName() {
    return AppFormModal.show<String>(
      context: context,
      builder: (modalContext) => const CreateFormatForm(),
    );
  }

  Future<void> _addFormat() async {
    final name = await _askFormatName();
    if (name == null || name.isEmpty || !mounted) return;
    final l10n = context.l10n;
    try {
      final format = await context.read<TitleFormCubit>().addFormat(name);
      if (!mounted) return;
      unawaited(context.read<ReferenceDataCubit>().refreshFormats());
      setState(() => _formatId = format.id);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final title = _title.text.trim();
    final author = _author.text.trim();
    final titleError = title.isEmpty ? l10n.validationFieldRequired : null;
    final authorError = author.isEmpty ? l10n.validationFieldRequired : null;
    final formatError = _formatId.isEmpty ? l10n.validationFieldRequired : null;
    final costError = _replacementCost.text.isValidMoney
        ? null
        : l10n.validationAmountInvalid;
    final copies = int.tryParse(_initialCopies.text);
    final copiesError = _isEditing
        ? null
        : (copies == null || copies < 1 ? l10n.validationCopiesMin : null);

    setState(() {
      _titleError = titleError;
      _authorError = authorError;
      _formatError = formatError;
      _costError = costError;
      _copiesError = copiesError;
    });

    if (titleError != null ||
        authorError != null ||
        formatError != null ||
        costError != null ||
        copiesError != null) {
      return;
    }

    try {
      await context.read<TitleFormCubit>().saveTitle(
        title: title,
        author: author,
        formatId: _formatId,
        isbn: _isbn.text.trim().isEmpty ? null : _isbn.text.trim(),
        publisher: _publisher.text.trim().isEmpty
            ? null
            : _publisher.text.trim(),
        publishedYear: int.tryParse(_year.text.trim()),
        edition: _edition.text.trim().isEmpty ? null : _edition.text.trim(),
        language: _language.text.trim().isEmpty
            ? 'English'
            : _language.text.trim(),
        pages: int.tryParse(_pages.text.trim()),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        shelf: _shelf.text.trim().isEmpty ? null : _shelf.text.trim(),
        lendable: _lendable,
        replacementCostText: _replacementCost.text,
        initialCopies: _isEditing ? 0 : copies!,
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
      title: _isEditing ? l10n.titleFormEditHeading : l10n.titleFormNewHeading,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: _close,
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.titleFormSave,
          isLoading: widget.isSaving,
          onPressed: () => unawaited(_save()),
        ),
      ],
      children: [
        TitleFormBibliographicSection(
          title: _title,
          author: _author,
          isbn: _isbn,
          publisher: _publisher,
          year: _year,
          edition: _edition,
          pages: _pages,
          language: _language,
          description: _description,
          formats: widget.formats,
          selectedFormat: _selectedFormat,
          titleError: _titleError,
          authorError: _authorError,
          formatError: _formatError,
          onTitleChanged: () {
            if (_titleError != null) setState(() => _titleError = null);
          },
          onAuthorChanged: () {
            if (_authorError != null) setState(() => _authorError = null);
          },
          onFormatChanged: (format) => setState(() {
            _formatId = format?.id ?? _formatId;
            _formatError = null;
          }),
          onAddFormat: () => unawaited(_addFormat()),
        ),
        TitleFormShelvingSection(
          shelf: _shelf,
          replacementCost: _replacementCost,
          initialCopies: _initialCopies,
          isEditing: _isEditing,
          costError: _costError,
          copiesError: _copiesError,
          lendable: _lendable,
          onCostChanged: () {
            if (_costError != null) setState(() => _costError = null);
          },
          onCopiesChanged: () {
            if (_copiesError != null) setState(() => _copiesError = null);
          },
          onLendableChanged: (value) => setState(() => _lendable = value),
        ),
      ],
    );
  }
}

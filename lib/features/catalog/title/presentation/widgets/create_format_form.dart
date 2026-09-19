// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The inline "new format" prompt behind the title form: one required
/// field, capped at 60 characters. Returns the name on confirm.
class CreateFormatForm extends StatefulWidget {
  const CreateFormatForm({super.key});

  @override
  State<CreateFormatForm> createState() => _CreateFormatFormState();
}

class _CreateFormatFormState extends State<CreateFormatForm> with DisposeBag {
  late final TextEditingController _name = textController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: l10n.titleFormCreateFormatHeading,
      width: AppDialogWidth.sm,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.titleFormAddFormat,
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              setState(() => _error = l10n.validationFieldRequired);
              return;
            }
            Navigator.of(context).pop(name);
          },
        ),
      ],
      children: [
        AppTextField(
          label: l10n.fieldFormat,
          required: true,
          controller: _name,
          errorText: _error,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      ],
    );
  }
}

// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A password field with a reveal toggle.
///
/// Masking is the default and stays the default between builds; revealing is
/// a deliberate, momentary act by whoever is at the keyboard. The toggle
/// matters most at a shared desk, where the alternative to seeing what you
/// typed is a lockout you have to ask an administrator to undo.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.hintText,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? hintText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppTextField(
      label: widget.label,
      required: true,
      controller: widget.controller,
      hintText: widget.hintText,
      errorText: widget.errorText,
      obscureText: !_revealed,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      suffixIcon: AppIconButton(
        icon: _revealed ? AppIcons.hidePassword : AppIcons.revealPassword,
        tooltip: _revealed ? l10n.authHidePassword : l10n.authRevealPassword,
        size: AppIconButtonSize.small,
        onPressed: () => setState(() => _revealed = !_revealed),
      ),
    );
  }
}

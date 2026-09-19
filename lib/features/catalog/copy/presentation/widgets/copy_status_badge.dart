// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A copy's standing as a pill.
///
/// The two-line wrapper exists so no screen has to remember that an overdue
/// copy is `danger` and a reserved one is `info` - the mapping lives once, on
/// the enum, and every table row reads it through here.
class CopyStatusBadge extends StatelessWidget {
  const CopyStatusBadge({
    required this.status,
    this.dense = true,
    super.key,
  });

  final CopyStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => AppStatusBadge(
    label: status.label(context.l10n),
    tone: status.tone,
    dense: dense,
  );
}

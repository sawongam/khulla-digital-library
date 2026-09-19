// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Questions the desk actually asks, each opening to its answer.
///
/// Closed by default, and one open at a time: the value of a question list is
/// that a reader can scan ten questions in the space three answers would take
/// and stop at the one that is theirs.
class GuideFaqList extends StatefulWidget {
  const GuideFaqList(this.faq, {super.key});

  /// The questions, most-asked first.
  final GuideFaq faq;

  @override
  State<GuideFaqList> createState() => _GuideFaqListState();
}

class _GuideFaqListState extends State<GuideFaqList> {
  int? _open;

  void _toggle(int index) =>
      setState(() => _open = _open == index ? null : index);

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final entries = widget.faq.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, entry) in entries.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == entries.length - 1 ? 0 : spacing.xs,
            ),
            child: AppCard(
              onTap: () => _toggle(index),
              selected: _open == index,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.question,
                          style: type.sectionTitle.copyWith(
                            color: colors.textHigh,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      AnimatedRotation(
                        turns: _open == index ? 0.5 : 0,
                        duration: context.appMotion.short,
                        child: AppIcon(
                          AppIcons.chevronDown,
                          size: 16,
                          color: colors.ink400,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: context.appMotion.short,
                    alignment: Alignment.topLeft,
                    child: _open == index
                        ? Padding(
                            padding: EdgeInsets.only(top: spacing.xs),
                            child: Text(
                              entry.answer,
                              style: type.body.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

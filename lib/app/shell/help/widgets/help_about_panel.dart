// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/services.dart';
import 'package:khulla/core/config/app_info.dart';
import 'package:khulla/core/config/app_version.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/widgets/app_logo.dart';
import 'package:khulla/shared/widgets/whatsapp_mark.dart';
import 'package:khulla_ui/khulla_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// What this product is, who built it, and where to find the source.
///
/// Every link here leaves the app, which is the one place in Khulla that
/// happens: the catalogue is local, and these addresses - asking for a hand,
/// and where the project lives - are the whole reason the operator would want
/// a browser.
class HelpAboutPanel extends StatelessWidget {
  const HelpAboutPanel({super.key});

  /// Opens [url] in the operator's browser.
  ///
  /// A desk machine with no browser registered, or a locked-down kiosk, will
  /// refuse the launch - so the fallback copies the address rather than
  /// failing silently, and the toast says which of the two happened.
  static Future<void> openLink(BuildContext context, String url) async {
    final l10n = context.l10n;
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (opened || !context.mounted) return;

    // A machine with no mail app gets the bare address, ready to paste.
    final uri = Uri.parse(url);
    final isMail = uri.scheme == 'mailto';
    await Clipboard.setData(ClipboardData(text: isMail ? uri.path : url));
    if (context.mounted) {
      AppToast.warning(
        context,
        message: isMail ? l10n.helpAboutEmailCopied : l10n.helpAboutLinkFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo beside the name keeps the identity to two lines, so the
        // actions below start on screen instead of under a tall banner.
        Row(
          children: [
            const AppLogo.submark(size: 56),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: spacing.xs,
                    runSpacing: spacing.xxs,
                    children: [
                      Text(
                        l10n.appName,
                        style: typography.title.copyWith(
                          color: colors.textHigh,
                        ),
                      ),
                      FutureBuilder<String>(
                        future: AppVersion.version(),
                        builder: (context, snapshot) => AppStatusBadge(
                          label:
                              '${l10n.helpAboutVersionLabel} '
                              '${snapshot.data ?? '…'}',
                          tone: AppStatusTone.brand,
                        ),
                      ),
                      const AppStatusBadge(label: AppInfo.license),
                    ],
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    l10n.helpAboutTagline,
                    style: typography.body.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final helpSection = _Section(
              icon: AppIcons.support,
              title: l10n.helpAboutHelpTitle,
              body: l10n.helpAboutHelpBody,
              fill: wide,
              children: [
                _LinkRow(
                  icon: AppIcons.email,
                  label: l10n.helpAboutContactEmail,
                  url: 'mailto:${AppInfo.email}',
                  display: AppInfo.email,
                  hint: l10n.helpAboutOpenMail,
                  section: const _WhatsappSection(),
                ),
              ],
            );
            final supportSection = _Section(
              icon: AppIcons.people,
              title: l10n.helpAboutSupportTitle,
              body: l10n.helpAboutSupportBody,
              tone: AppStatusTone.brand,
              fill: wide,
              children: [
                _LinkRow(
                  icon: AppIcons.email,
                  label: l10n.helpAboutSupportContact,
                  url: 'mailto:${AppInfo.fundingEmail}',
                  display: AppInfo.fundingEmail,
                  hint: l10n.helpAboutOpenMail,
                ),
              ],
            );
            final links = [
              _LinkRow(
                icon: AppIcons.discover,
                label: l10n.helpAboutLinkWebsite,
                url: AppInfo.websiteUrl,
              ),
              _LinkRow(
                icon: AppIcons.article,
                label: l10n.helpAboutLinkRepository,
                url: AppInfo.repositoryUrl,
              ),
              _LinkRow(
                icon: AppIcons.error,
                label: l10n.helpAboutLinkIssues,
                url: AppInfo.issuesUrl,
              ),
            ];
            final linksSection = _Section(
              icon: AppIcons.discover,
              title: l10n.helpAboutLinksTitle,
              // Side by side when wide: three short rows in one line read as
              // a footer of destinations, not a third competing card.
              inline: wide,
              children: links,
            );

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  helpSection,
                  SizedBox(height: spacing.md),
                  supportSection,
                  SizedBox(height: spacing.md),
                  linksSection,
                ],
              );
            }
            // The two prose cards share a height so their actions line up on
            // one baseline; the links run full width beneath them.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: helpSection),
                      SizedBox(width: spacing.md),
                      Expanded(child: supportSection),
                    ],
                  ),
                ),
                SizedBox(height: spacing.md),
                linksSection,
              ],
            );
          },
        ),
        SizedBox(height: spacing.md),
        Text(
          l10n.helpAboutOpenSource,
          textAlign: TextAlign.center,
          style: typography.caption.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

/// One labelled block of the panel: a heading, an optional sentence of
/// context, and its links in a bordered card, split by hairlines.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
    this.body,
    this.tone,
    this.fill = false,
    this.inline = false,
  });

  /// Stretch the card to the height it is given, pinning the links to its foot.
  final bool fill;

  /// Lay the children out in one row, split by vertical hairlines.
  final bool inline;
  final AppIconSpec icon;
  final String title;
  final String? body;
  final AppStatusTone? tone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;

    final bodyText = body == null
        ? null
        : Padding(
            padding: EdgeInsets.all(spacing.xs),
            child: Text(
              body!,
              style: typography.body.copyWith(color: colors.textMuted),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: title, icon: icon, dense: true),
        SizedBox(height: spacing.xs),
        _maybeExpand(
          AppCard(
            tone: tone,
            padding: EdgeInsets.all(spacing.xs),
            child: inline
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0)
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: colors.hairline,
                            ),
                          Expanded(child: children[i]),
                        ],
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (bodyText != null && fill) Expanded(child: bodyText),
                      if (bodyText != null && !fill) bodyText,
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0 || bodyText != null)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colors.hairline,
                          ),
                        children[i],
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _maybeExpand(Widget card) => fill ? Expanded(child: card) : card;
}

/// One link: what it is, where it points, and the button that opens it.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
    this.display,
    this.hint,
    this.section,
  });

  final AppIconSpec icon;
  final String label;
  final String url;

  /// What to show under [label] instead of [url], when the address reads
  /// better than the link: a phone number, or an email without `mailto:`.
  /// Without one, the URL is shown without its scheme.
  final String? display;

  /// The tooltip, when the row opens something other than the browser.
  final String? hint;

  /// A separate tappable cell at the row's end, for a second way to reach the
  /// same place. It has its own action, so it sits outside the row's tap area.
  final Widget? section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;
    final radius = BorderRadius.circular(context.appRadius.control);

    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: hint ?? l10n.helpAboutOpenLink,
            waitDuration: const Duration(milliseconds: 700),
            child: InkWell(
              onTap: () => HelpAboutPanel.openLink(context, url),
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.xs,
                  vertical: spacing.xs,
                ),
                child: Row(
                  children: [
                    AppIcon(icon, size: 18, color: colors.mutedForeground),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: typography.label.copyWith(
                              color: colors.textHigh,
                            ),
                          ),
                          Text(
                            display ??
                                url.replaceFirst(RegExp('^https?://'), ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.caption.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppIcon(
                      AppIcons.openExternal,
                      size: 16,
                      color: colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (section != null) ...[
          SizedBox(width: spacing.xs),
          Container(width: 1, height: 28, color: colors.hairline),
          SizedBox(width: spacing.xs),
          section!,
        ],
      ],
    );
  }
}

/// WhatsApp as its own cell at the end of the email row.
class _WhatsappSection extends StatelessWidget {
  const _WhatsappSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Tooltip(
      message: l10n.helpAboutOpenWhatsapp,
      child: Semantics(
        button: true,
        label: l10n.helpAboutContactWhatsapp,
        child: InkWell(
          onTap: () => HelpAboutPanel.openLink(context, AppInfo.whatsappUrl),
          borderRadius: BorderRadius.circular(context.appRadius.control),
          child: Padding(
            padding: EdgeInsets.all(context.appSpacing.sm),
            child: WhatsappMark(
              size: 20,
              color: context.appColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

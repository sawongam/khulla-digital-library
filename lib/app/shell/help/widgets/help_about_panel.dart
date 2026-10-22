// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/services.dart';
import 'package:khulla/core/config/app_info.dart';
import 'package:khulla/core/config/app_version.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/widgets/app_logo.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Column(
            children: [
              const AppLogo.submark(size: 64),
              SizedBox(height: spacing.sm),
              Text(
                l10n.appName,
                style: typography.title.copyWith(color: colors.textHigh),
              ),
              SizedBox(height: spacing.xxs),
              Text(
                l10n.helpAboutTagline,
                textAlign: TextAlign.center,
                style: typography.body.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.md),
        AppDetailRow(
          label: l10n.helpAboutVersionLabel,
          child: FutureBuilder<String>(
            future: AppVersion.version(),
            builder: (context, snapshot) {
              final version = snapshot.data;
              if (version == null) {
                return Text(
                  '…',
                  style: typography.body.copyWith(color: colors.textHigh),
                );
              }
              return Text(
                version,
                style: typography.body.copyWith(color: colors.textHigh),
              );
            },
          ),
        ),
        AppDetailRow(
          label: l10n.helpAboutAuthorTitle,
          child: const _AuthorLink(),
        ),
        SizedBox(height: spacing.md),
        AppSectionHeader(title: l10n.helpAboutHelpTitle, dense: true),
        SizedBox(height: spacing.xs),
        Text(
          l10n.helpAboutHelpBody,
          style: typography.body.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: spacing.sm),
        _LinkRow(
          icon: AppIcons.support,
          label: l10n.helpAboutContactWhatsapp,
          url: AppInfo.whatsappUrl,
          display: AppInfo.whatsappDisplay,
          hint: l10n.helpAboutOpenWhatsapp,
        ),
        _LinkRow(
          icon: AppIcons.email,
          label: l10n.helpAboutContactEmail,
          url: 'mailto:${AppInfo.email}',
          display: AppInfo.email,
          hint: l10n.helpAboutOpenMail,
        ),
        SizedBox(height: spacing.md),
        AppSectionHeader(title: l10n.helpAboutLinksTitle, dense: true),
        SizedBox(height: spacing.sm),
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
        SizedBox(height: spacing.sm),
        Text(
          l10n.helpAboutOpenSource,
          style: typography.caption.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

/// The author's name, which is also the way to their site.
class _AuthorLink extends StatelessWidget {
  const _AuthorLink();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: context.l10n.helpAboutAuthorLinkHint(AppInfo.authorName),
        child: AppLinkButton(
          color: colors.brandStrong,
          onPressed: () => HelpAboutPanel.openLink(context, AppInfo.authorSite),
          child: const Text(AppInfo.authorName),
        ),
      ),
    );
  }
}

/// One link: what it is, where it points, and the button that opens it.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
    this.display,
    this.hint,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;
    final radius = BorderRadius.circular(context.appRadius.control);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.xxs),
      child: Tooltip(
        message: hint ?? l10n.helpAboutOpenLink,
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
                        display ?? url.replaceFirst(RegExp('^https?://'), ''),
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
    );
  }
}
